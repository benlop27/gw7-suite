import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import 'effects_screen.dart';
import 'models/tone_catalog.dart';
import 'preset_screen.dart';
import 'services/midi_service.dart';
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
      title: 'GW-7 Presets',
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
  ToneCatalog? _catalog;
  String? _loadError;
  int _tab = 0;
  static const int _channel = 3;
  MidiDevice? _device;

  @override
  void initState() {
    super.initState();
    _load();
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
  }

  void _disconnect() {
    _midi.disconnect();
    setState(() => _device = null);
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
                            PresetScreen(
                              catalog: catalog,
                              midi: _midi,
                              channel: _channel,
                            ),
                            EffectsScreen(
                              catalog: catalog,
                              midi: _midi,
                              channel: _channel,
                            ),
                            UtilsScreen(
                              catalog: catalog,
                              midi: _midi,
                              channel: _channel,
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
            'GW-7',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).display,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
          final subtitle = Text(
            _tab == 0 ? 'PRESETS' : _tab == 1 ? 'EFFECTS' : 'UTILS',
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
