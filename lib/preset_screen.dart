import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/tone_catalog.dart';
import 'services/midi_service.dart';
import 'theme/app_theme.dart';

const Map<String, IconData> _bankIcons = {
  'PIANO': Icons.piano,
  'ELECTRIC PIANO': Icons.piano,
  'ORGAN': Icons.apartment,
  'ACCORDION': Icons.tune,
  'KEYBOARD': Icons.keyboard_alt,
  'CHROMATIC PERC': Icons.waves,
  'ACOUSTIC GUITAR': Icons.music_note,
  'ELECTRIC GUITAR': Icons.bolt,
  'BASS': Icons.volume_down,
  'STRINGS': Icons.queue_music,
  'VOCAL': Icons.mic,
  'SAX': Icons.air,
  'WIND': Icons.wind_power,
  'ACOUSTIC BRASS': Icons.campaign,
  'SYNTH BRASS': Icons.bolt,
  'SYNTH LEAD': Icons.graphic_eq,
  'POLY SYNTHESIZER': Icons.radio,
  'PAD': Icons.cloud,
  'WORLD 1': Icons.public,
  'WORLD 2': Icons.public,
  'PERCUSSION': Icons.circle,
  'SFX': Icons.auto_awesome,
  'DRUMS': Icons.donut_large,
};

class PresetScreen extends StatefulWidget {
  const PresetScreen({
    super.key,
    required this.catalog,
    required this.midi,
    required this.channel,
  });

  final ToneCatalog catalog;
  final MidiService midi;
  final int channel;

  @override
  State<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  late final MidiService _midi = widget.midi;

  int _bankIndex = 0;
  int? _selectedTone;
  double _masterVolume = 100;

  void _selectTone(ToneBank bank, Tone tone, int idx) {
    setState(() {
      _bankIndex = widget.catalog.banks.indexOf(bank);
      _selectedTone = idx;
    });
    _midi.sendTone(
      cc00: tone.cc00,
      cc32: tone.cc32,
      pc: tone.pc,
      channel: widget.channel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    return _content(catalog);
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
                      ? 'ch${widget.channel + 1} · ${tone.name}'
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _bankTabs(catalog),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _toneGrid(bank)),
                _volumeRail(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _volumeRail() {
    final theme = Gw7Theme.of(context);
    return Container(
      width: 64,
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            'VOL',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: theme.textDim,
            ),
          ),
          const SizedBox(height: 2),
          Icon(Icons.volume_up_rounded, size: 20, color: theme.textDim),
          const SizedBox(height: 6),
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 14,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 28,
                  ),
                ),
                child: Slider(
                  value: _masterVolume,
                  min: 0,
                  max: 127,
                  onChanged: (v) {
                    setState(() => _masterVolume = v);
                    _midi.sendMasterVolume(v.round());
                  },
                ),
              ),
            ),
          ),
          Text(
            '${_masterVolume.round()}',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lcd({required String text, bool big = false}) {
    final theme = Gw7Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: big ? 18 : 12,
        vertical: big ? 12 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 10)],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: Gw7Fonts.of(context).mono,
          fontWeight: FontWeight.w700,
          fontSize: big ? 22 : 13,
          color: theme.primary,
        ),
      ),
    );
  }

  Widget _bankTabs(ToneCatalog catalog) {
    final banks = catalog.banks;
    final rowCount = (banks.length / 2).ceil();
    final theme = Gw7Theme.of(context);
    return Column(
      children: [
        for (int r = 0; r < 2; r++) ...[
          if (r > 0) const SizedBox(height: 4),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: r == 0 ? rowCount : banks.length - rowCount,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final idx = r * rowCount + i;
                final bank = banks[idx];
                final active = idx == _bankIndex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _bankIndex = idx;
                    _selectedTone = null;
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: active
                          ? theme.primaryContainer.withValues(alpha: 0.12)
                          : theme.surfaceLow,
                      border: Border.all(
                        color: active
                            ? theme.primaryContainer
                            : theme.border,
                        width: active ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: theme.primaryContainer.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _bankIcons[bank.name] ?? Icons.music_note,
                          size: 18,
                          color: active ? theme.primary : theme.textDim,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bank.name,
                          style: TextStyle(
                            fontFamily: Gw7Fonts.of(context).mono,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: active ? theme.primary : theme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _toneGrid(ToneBank bank) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final theme = Gw7Theme.of(context);
        final cols = width >= 900
            ? 8
            : width >= 600
                ? 6
                : width >= 400
                    ? 4
                    : 3;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(6),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.4,
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
                        ? theme.primaryContainer.withValues(alpha: 0.15)
                        : theme.surfaceHigh,
                    border: Border.all(
                      color: selected
                          ? theme.primaryContainer
                          : theme.border,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: theme.primaryContainer.withValues(
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
                          fontFamily: Gw7Fonts.of(context).mono,
                          fontSize: math.max(12, width / cols / 10),
                          fontWeight: FontWeight.w700,
                          color: selected ? theme.primary : theme.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          tone.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: Gw7Fonts.of(context).ui,
                            fontSize: math.max(10, width / cols / 13),
                            color: selected ? theme.primary : theme.textDim,
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
      },
    );
  }
}
