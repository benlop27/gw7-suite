import 'package:flutter/material.dart';

import 'models/tone_catalog.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';

/// Effects tab: stage-level MIDI CC controllers — attack, release, reverb/
/// chorus sends, expression and pan — sent on the active part channel.
class EffectsScreen extends StatefulWidget {
  const EffectsScreen({
    super.key,
    required this.catalog,
    required this.controller,
  });

  final ToneCatalog catalog;
  final AppController controller;

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
  AppController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final s = _controller.state;
        final theme = Gw7Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.surface,
                  border: Border.all(color: theme.border),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune,
                        size: 16, color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'QUICK CC',
                        style: TextStyle(
                          fontFamily: Gw7Fonts.of(context).display,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryContainer.withValues(alpha: 0.15),
                        border: Border.all(color: theme.primaryContainer),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'SENT ON CH${_controller.presetChannel + 1}',
                        style: TextStyle(
                          fontFamily: Gw7Fonts.of(context).mono,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth >= 700 ? 3 : 2;
                    final cells = [
                      _CcCell(
                        label: 'ATTACK',
                        cc: 73,
                        value: s.ccAttack,
                        onChanged: _controller.setCcAttack,
                      ),
                      _CcCell(
                        label: 'RELEASE',
                        cc: 72,
                        value: s.ccRelease,
                        onChanged: _controller.setCcRelease,
                      ),
                      _CcCell(
                        label: 'REVERB',
                        cc: 91,
                        value: s.ccReverb,
                        onChanged: _controller.setCcReverb,
                      ),
                      _CcCell(
                        label: 'CHORUS',
                        cc: 93,
                        value: s.ccChorus,
                        onChanged: _controller.setCcChorus,
                      ),
                      _CcCell(
                        label: 'EXPR',
                        cc: 11,
                        value: s.ccExpr,
                        onChanged: _controller.setCcExpr,
                      ),
                      _CcCell(
                        label: 'PAN',
                        cc: 10,
                        value: s.ccPan,
                        onChanged: _controller.setCcPan,
                      ),
                    ];
                    final rows = <Widget>[];
                    for (int i = 0; i < cells.length; i += cols) {
                      final rowCells = cells.sublist(
                        i,
                        (i + cols).clamp(0, cells.length),
                      );
                      rows.add(Row(
                        children: [
                          for (int j = 0; j < rowCells.length; j++) ...[
                            if (j > 0) const SizedBox(width: 12),
                            Expanded(child: rowCells[j]),
                          ],
                        ],
                      ));
                    }
                    return Column(
                      children: [
                        for (int i = 0; i < rows.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          Expanded(child: rows[i]),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Large grid cell for one quick CC: label + controller number on top,
/// 0–127 slider in the middle, numeric readout below.
class _CcCell extends StatelessWidget {
  const _CcCell({
    required this.label,
    required this.cc,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int cc;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Gw7Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceLow,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: Gw7Fonts.of(context).mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: theme.text,
                  ),
                ),
              ),
              Text(
                'CC$cc',
                style: TextStyle(
                  fontFamily: Gw7Fonts.of(context).mono,
                  fontSize: 10,
                  letterSpacing: 0.6,
                  color: theme.textDim,
                ),
              ),
            ],
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: theme.primaryContainer,
                inactiveTrackColor: theme.border,
                thumbColor: theme.primary,
                overlayColor: theme.primary.withValues(alpha: 0.15),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              ),
              child: Slider(
                value: value.toDouble(),
                max: 127,
                divisions: 127,
                label: '$value',
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
          ),
          Text(
            '$value',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
