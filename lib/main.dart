import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import 'effects_screen.dart';
import 'models/tone_catalog.dart';
import 'preset_screen.dart';
import 'services/app_controller.dart';
import 'services/midi_service.dart';
import 'services/web_debug_stub.dart'
    if (dart.library.js_interop) 'services/web_debug.dart';
import 'stage_screen.dart';
import 'theme/app_theme.dart';
import 'utils_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Gw7App());
}

class Gw7App extends StatelessWidget {
  const Gw7App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GW-7 Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.studio.buildTheme(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MidiService _midi = MidiService();
  late final AppController _controller = AppController(_midi, _channel);
  ToneCatalog? _catalog;
  String? _loadError;
  int _tab = 0;
  static const int _channel = 3;
  MidiDevice? _device;
  List<MidiDevice> _availableDevices = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _load();
    _controller.load();
    exposeWebDebug(_midi);
    _midi.onSetupChanged?.listen((change) {
      if (!mounted) return;
      _refreshDevices();
    });
    _midi.onDataReceived?.listen((event) {
      if (!mounted) return;
      final buf = StringBuffer('RX');
      for (final b in event.message.data) {
        buf.write(' ${_hex(b)}');
      }
      _midi.lastRx.value = buf.toString();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _midi.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final catalog = await ToneCatalog.load();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loadError = null;
      });
      _autoConnect();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Catalog load failed: $e');
    }
  }

  Future<void> _autoConnect() async {
    final connected = await _midi.connectBridge();
    if (!mounted) return;
    setState(() => _device = connected ? _midi.device : _device);
    _syncAfterConnect();
  }

  Future<void> _refreshDevices() async {
    final devices = await _midi.scanDevices();
    if (!mounted) return;
    final stillThere = devices.where((d) => d.connected).toList();
    setState(() {
      if (stillThere.isNotEmpty) {
        _device = stillThere.first;
      } else if (_device != null && !devices.any((d) => d.id == _device!.id)) {
        _device = null;
      }
    });
  }

  Future<void> _connect() async {
    final connected = await _midi.connectBridge();
    if (!mounted) return;
    setState(() => _device = connected ? _midi.device : _device);
    _syncAfterConnect();
  }

  Future<void> _connectToDevice(MidiDevice device) async {
    try {
      await _midi.connect(device);
    } catch (_) {
      // Connection failures surface through the status pill.
    }
    if (!mounted) return;
    setState(() => _device = _midi.device);
    _syncAfterConnect();
  }

  Future<void> _openDevicePicker() async {
    final devices = await _midi.listDevices();
    if (!mounted) return;
    setState(() => _availableDevices = devices);
  }

  void _disconnect() {
    _midi.disconnect();
    setState(() => _device = null);
  }

  /// After a successful connect, push the stored app state to the keyboard
  /// so the GW-7 recalls the last setup automatically.
  Future<void> _syncAfterConnect() async {
    final catalog = _catalog;
    if (_device == null || catalog == null) return;
    await _controller.load();
    if (!mounted) return;
    _controller.syncToKeyboard(catalog);
  }

  Future<void> _syncNow() async {
    final catalog = _catalog;
    if (_device == null || catalog == null) {
      _snack('Connect to the GW-7 first');
      return;
    }
    if (_syncing) return;
    setState(() => _syncing = true);
    await _controller.save();
    _controller.syncToKeyboard(catalog);
    if (!mounted) return;
    setState(() => _syncing = false);
    _snack('Synced to GW-7');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ));
  }

  String _hex(int b) =>
      '0${(b & 0xff).toRadixString(16).toUpperCase()}'.substring(1);

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    )
                  : catalog == null
                      ? const Center(child: CircularProgressIndicator())
                      : IndexedStack(
                          index: _tab,
                          children: [
                            StageScreen(
                              catalog: catalog,
                              controller: _controller,
                            ),
                            PresetScreen(
                              catalog: catalog,
                              controller: _controller,
                            ),
                            EffectsScreen(
                              catalog: catalog,
                              controller: _controller,
                            ),
                            UtilsScreen(
                              catalog: catalog,
                              midi: _midi,
                              controller: _controller,
                            ),
                          ],
                        ),
            ),
            _footer(),
          ],
        ),
      ),
      bottomNavigationBar: catalog == null
          ? null
          : NavigationBar(
              backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.star_outline_rounded),
                  selectedIcon: const Icon(Icons.star_rounded),
                  label: 'Stage',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.piano_outlined),
                  selectedIcon: const Icon(Icons.piano),
                  label: 'Presets',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.tune_outlined),
                  selectedIcon: const Icon(Icons.tune),
                  label: 'Effects',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.widgets_outlined),
                  selectedIcon: const Icon(Icons.widgets),
                  label: 'Utils',
                ),
              ],
            ),
    );
  }

  Widget _topBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          final title = Text(
            'GW-7 STUDIO',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).display,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
          final subtitle = Text(
            _tab == 0
                ? 'STAGE'
                : _tab == 1
                    ? 'PRESETS'
                    : _tab == 2
                        ? 'EFFECTS'
                        : 'UTILS',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, subtitle],
          );
          final connect = _device == null
              ? ElevatedButton(
                  onPressed: _connect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Connect'),
                )
              : OutlinedButton(
                  onPressed: _disconnect,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Disconnect'),
                );
          final sync = OutlinedButton.icon(
            onPressed: _syncing ? null : _syncNow,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: _device == null
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.primary,
            ),
            icon: _syncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.sync_rounded,
                    size: 16,
                    color: _device == null
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.primary),
            label: const Text('SYNC'),
          );
          final picker = PopupMenuButton<MidiDevice>(
            tooltip: 'Choose MIDI device',
            onOpened: _openDevicePicker,
            icon: Icon(
              Icons.settings_input_component,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            itemBuilder: (context) {
              if (_availableDevices.isEmpty) {
                return const [
                  PopupMenuItem<MidiDevice>(
                    enabled: false,
                    child: Text('No MIDI devices'),
                  ),
                ];
              }
              return [
                for (final d in _availableDevices)
                  PopupMenuItem<MidiDevice>(
                    value: d,
                    child: Row(
                      children: [
                        Icon(
                          _device?.id == d.id
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 16,
                          color: _device?.id == d.id
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            d.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ];
            },
            onSelected: _connectToDevice,
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    titleBlock,
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _statusPill()),
                    const SizedBox(width: 8),
                    picker,
                    const SizedBox(width: 8),
                    sync,
                    const SizedBox(width: 8),
                    connect,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              titleBlock,
              const Spacer(),
              _statusPill(),
              const SizedBox(width: 8),
              picker,
              const SizedBox(width: 8),
              sync,
              const SizedBox(width: 8),
              connect,
            ],
          );
        },
      ),
    );
  }

  Widget _statusPill() {
    return ValueListenableBuilder<MidiStatus>(
      valueListenable: _midi.status,
      builder: (context, status, _) {
        final scheme = Theme.of(context).colorScheme;
        final Color ledColor;
        if (status.error) {
          ledColor = scheme.error;
        } else if (status.ok) {
          ledColor = scheme.tertiary;
        } else {
          ledColor = scheme.onSurfaceVariant;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            border: Border.all(color: scheme.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ledColor,
                  shape: BoxShape.circle,
                  boxShadow: status.ok || status.error
                      ? [
                          BoxShadow(
                            color: ledColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  status.text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Gw7Fonts.of(context).mono,
                    fontSize: 11,
                    color: ledColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ValueListenableBuilder<String>(
        valueListenable: _midi.lastMessage,
        builder: (context, msg, _) => Text(
          msg,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: Gw7Fonts.of(context).mono,
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

Future<ToneCatalog> loadCatalog() => ToneCatalog.load();
