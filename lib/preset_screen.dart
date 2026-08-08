import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/app_state.dart';
import 'models/tone_catalog.dart';
import 'services/app_controller.dart';
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
    required this.controller,
  });

  final ToneCatalog catalog;
  final AppController controller;

  @override
  State<PresetScreen> createState() => _PresetScreenState();
}

class _PresetScreenState extends State<PresetScreen> {
  AppController get _controller => widget.controller;

  void _selectTone(ToneBank bank, Tone tone, int idx) {
    _controller.selectTone(
      bankIndex: widget.catalog.banks.indexOf(bank),
      toneIndex: idx,
      cc00: tone.cc00,
      cc32: tone.cc32,
      pc: tone.pc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = widget.catalog;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => _content(catalog),
    );
  }


  Widget _content(ToneCatalog catalog) {
    final state = _controller.state;
    final bank = catalog.banks[state.presetBankIndex];
    final tone = state.presetToneIndex != null &&
            state.presetToneIndex! < bank.tones.length
        ? bank.tones[state.presetToneIndex!]
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
                      ? '${bank.name} ${(state.presetToneIndex! + 1).toString().padLeft(3, '0')}'
                      : '— / —',
                  big: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _lcd(
                  text: tone != null
                      ? 'ch${_controller.channel + 1} · ${tone.name}'
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _bankTabs(catalog),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _toneGrid(bank)),
                _volumeRail(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _volumeRail(AppState state) {
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
                  value: state.masterVolume.toDouble(),
                  min: 0,
                  max: 127,
                  onChanged: (v) => _controller.setMasterVolume(v.round()),
                ),
              ),
            ),
          ),
          Text(
            '${state.masterVolume}',
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
                final active = idx == _controller.state.presetBankIndex;
                return GestureDetector(
                  onTap: () => _controller.selectBank(idx),
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
              final selected = idx == _controller.state.presetToneIndex;
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
