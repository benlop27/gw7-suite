import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import 'models/tone_catalog.dart';
import 'services/midi_service.dart';

class PresetScreen extends StatefulWidget {
  const PresetScreen({super.key});

  @override
  State<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  final MidiService _midi = MidiService();

  ToneCatalog? _catalog;
  String? _loadError;
  int _bankIndex = 0;
  int? _selectedTone;
  int _channel = 0;
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

  Future<void> _load() async {
    try {
      final catalog = await ToneCatalog.load();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Catalog load failed: $e');
    }
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
    final devices = await _midi.scanDevices();
    if (!mounted) return;
    if (devices.isEmpty) return;
    final device = devices.firstWhere(
      (d) => d.type == MidiDeviceType.serial,
      orElse: () => devices.first,
    );
    setState(() => _device = device);
    await _midi.connect(device);
  }

  void _disconnect() {
    _midi.disconnect();
    setState(() => _device = null);
  }

  void _selectTone(ToneBank bank, Tone tone, int idx) {
    setState(() {
      _bankIndex = _catalog!.banks.indexOf(bank);
      _selectedTone = idx;
    });
    _midi.sendTone(
      cc00: tone.cc00,
      cc32: tone.cc32,
      pc: tone.pc,
      channel: _channel,
    );
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
            _topBar(context),
            Expanded(
              child: _loadError != null
                  ? _centerMessage(_loadError!)
                  : catalog == null
                      ? const Center(child: CircularProgressIndicator())
                      : _content(catalog),
            ),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Text(
            'GW-7 PRESETS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<MidiStatus>(
            valueListenable: _midi.status,
            builder: (context, status, _) {
              final Color ledColor;
              if (status.error) {
                ledColor = const Color(0xFF93000A);
              } else if (status.ok) {
                ledColor = const Color(0xFF41DDC2);
              } else {
                ledColor = const Color(0xFF333333);
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0E0E),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        status.text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: status.error
                              ? const Color(0xFFFFB4AB)
                              : status.ok
                                  ? const Color(0xFF41DDC2)
                                  : const Color(0xFF8A8A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          if (_device == null)
            ElevatedButton(
              onPressed: _connect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6600),
                foregroundColor: Colors.white,
              ),
              child: const Text('Connect'),
            )
          else
            OutlinedButton(
              onPressed: _disconnect,
              child: const Text('Disconnect'),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2D2D2D)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CH ',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
                DropdownButton<int>(
                  value: _channel,
                  dropdownColor: const Color(0xFF0E0E0E),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Color(0xFFE5E2E1),
                  ),
                  underline: const SizedBox.shrink(),
                  items: [
                    for (int i = 0; i < 16; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text('${i + 1}${i == 9 ? ' (drum)' : ''}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _channel = v!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(ToneCatalog catalog) {
    final bank = catalog.banks[_bankIndex];
    final tone = _selectedTone != null && _selectedTone! < bank.tones.length
        ? bank.tones[_selectedTone!]
        : null;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _lcd(
                  text: tone != null
                      ? '${bank.name} ${(_selectedTone! + 1).toString().padLeft(3, '0')}'
                      : '— / —',
                  big: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lcd(
                  text: tone != null
                      ? 'ch${_channel + 1} · ${tone.name}'
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _bankTabs(catalog),
          const SizedBox(height: 12),
          Expanded(child: _toneGrid(bank)),
        ],
      ),
    );
  }

  Widget _lcd({required String text, bool big = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: big ? 18 : 12,
        vertical: big ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 10)],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w700,
          fontSize: big ? 22 : 13,
          color: const Color(0xFFFFB596),
        ),
      ),
    );
  }

  Widget _bankTabs(ToneCatalog catalog) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: catalog.banks.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final bank = catalog.banks[i];
          final active = i == _bankIndex;
          return GestureDetector(
            onTap: () => setState(() {
              _bankIndex = i;
              _selectedTone = null;
            }),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0x1FFF6600)
                    : const Color(0xFF0E0E0E),
                border: Border.all(
                  color: active
                      ? const Color(0xFFFF6600)
                      : const Color(0xFF2D2D2D),
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6600).withValues(
                            alpha: 0.25,
                          ),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                bank.name,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: active
                      ? const Color(0xFFFFB596)
                      : const Color(0xFF8A8A8A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _toneGrid(ToneBank bank) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2D2D2D)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(6),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.6,
        ),
        itemCount: bank.tones.length,
        itemBuilder: (context, idx) {
          final tone = bank.tones[idx];
          final selected = idx == _selectedTone;
          return GestureDetector(
            onTap: () => _selectTone(bank, tone, idx),
            child: Container(
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0x26FF6600)
                    : const Color(0xFF201F1F),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF6600)
                      : const Color(0xFF2D2D2D),
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF6600).withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${tone.no}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? const Color(0xFFFFB596)
                          : const Color(0xFFE5E2E1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      tone.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? const Color(0xFFFFB596)
                            : const Color(0xFF8A8A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: ValueListenableBuilder<String>(
        valueListenable: _midi.lastMessage,
        builder: (context, msg, _) => Text(
          msg,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Color(0xFF5F5F5F),
          ),
        ),
      ),
    );
  }

  Widget _centerMessage(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFB4AB)),
          ),
        ),
      );
}
