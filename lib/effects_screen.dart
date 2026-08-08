import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/tone_catalog.dart';
import 'services/midi_service.dart';
import 'theme/app_theme.dart';

const Map<String, IconData> _panelIcons = {
  'REVERB': Icons.airplay,
  'CHORUS': Icons.waves,
  'INSERTION MFX': Icons.tune,
};

const Map<String, IconData> _categoryIcons = {
  'REVERB': Icons.airplay,
  'PITCH': Icons.tune,
  'DRIVE': Icons.bolt,
  'MOD/DELAY': Icons.waves,
  'EQ': Icons.graphic_eq,
};

class EffectsScreen extends StatefulWidget {
  const EffectsScreen({
    super.key,
    required this.catalog,
    required this.midi,
    required this.channel,
  });

  final ToneCatalog catalog;
  final MidiService midi;
  final int channel;

  @override
  State<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends State<EffectsScreen> {
  late final EffectInfo _fx = widget.catalog.effects;

  bool _reverbOn = false;
  bool _chorusOn = false;
  bool _mfxOn = false;

  int _reverbType = 0;
  int _reverbTime = 0;
  static const int _reverbSend = 40;

  int _chorusType = 0;
  int _chorusRate = 0;
  int _chorusDepth = 0;
  int _chorusFeedback = 0;
  static const int _chorusSendDefault = 40;
  int _chorusSend = _chorusSendDefault;

  int _mfxType = 0;
  int _mfxBalance = 0;
  int _mfxLevel = 0;

  void _sendReverb(int param, int value) =>
      widget.midi.sendReverb(param: param, value: value);

  void _sendChorus(int param, int value) =>
      widget.midi.sendChorus(param: param, value: value);

  void _setReverbOn(bool on) {
    setState(() => _reverbOn = on);
    widget.midi.sendPartReverbSend(
      channel: widget.channel,
      value: on ? _reverbSend : 0,
    );
    if (on) {
      _sendReverb(0, _reverbType);
      _sendReverb(1, _reverbTime);
    }
  }

  void _setChorusOn(bool on) {
    setState(() => _chorusOn = on);
    widget.midi.sendPartChorusSend(
      channel: widget.channel,
      value: on ? _chorusSend : 0,
    );
    if (on) {
      _sendChorus(0, _chorusType);
      _sendChorus(1, _chorusRate);
      _sendChorus(2, _chorusDepth);
      _sendChorus(3, _chorusFeedback);
      _sendChorus(4, _chorusSend);
    }
  }

  void _setMfxOn(bool on) {
    setState(() => _mfxOn = on);
    widget.midi.sendPartMfxAssign(channel: widget.channel, value: on ? 1 : 0);
    if (on) {
      widget.midi.sendMfx(offset: 0x00, value: _mfxType);
      widget.midi.sendMfx(offset: _fx.mfxBalanceOffset, value: _mfxBalance);
      widget.midi.sendMfx(offset: _fx.mfxLevelOffset, value: _mfxLevel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = <Widget>[
      _panel(
        title: 'REVERB',
        on: _reverbOn,
        onToggle: _setReverbOn,
        children: [
          _typeRow(label: 'TYPE', types: _fx.reverbTypes, value: _reverbType,
            onChanged: (v) { _reverbType = v; _sendReverb(0, v); }),
          _sliderArea([
            _ParamSlider(label: 'TIME', value: _reverbTime,
              onChanged: (v) => setState(() { _reverbTime = v; _sendReverb(1, v); })),
          ]),
        ],
      ),
      _panel(
        title: 'CHORUS',
        on: _chorusOn,
        onToggle: _setChorusOn,
        children: [
          _typeRow(label: 'TYPE', types: _fx.chorusTypes, value: _chorusType,
            onChanged: (v) { _chorusType = v; _sendChorus(0, v); }),
          _sliderArea([
            _ParamSlider(label: 'RATE', value: _chorusRate,
              onChanged: (v) => setState(() { _chorusRate = v; _sendChorus(1, v); })),
            _ParamSlider(label: 'DEPTH', value: _chorusDepth,
              onChanged: (v) => setState(() { _chorusDepth = v; _sendChorus(2, v); })),
            _ParamSlider(label: 'FEEDBACK', value: _chorusFeedback,
              onChanged: (v) => setState(() { _chorusFeedback = v; _sendChorus(3, v); })),
            _ParamSlider(label: 'SEND', value: _chorusSend,
              onChanged: (v) => setState(() {
                _chorusSend = v;
                _sendChorus(4, v);
                widget.midi.sendPartChorusSend(channel: widget.channel, value: v);
              })),
          ]),
        ],
      ),
      _panel(
        title: 'INSERTION MFX',
        on: _mfxOn,
        onToggle: _setMfxOn,
        children: [
          _typeDropdown(label: 'TYPE', types: _fx.mfxTypes, value: _mfxType,
            onChanged: (v) { _mfxType = v; widget.midi.sendMfx(offset: 0x00, value: v); }),
          _sliderArea([
            _ParamSlider(label: 'BALANCE', value: _mfxBalance,
              onChanged: (v) => setState(() { _mfxBalance = v; widget.midi.sendMfx(offset: _fx.mfxBalanceOffset, value: v); })),
            _ParamSlider(label: 'LEVEL', value: _mfxLevel,
              onChanged: (v) => setState(() { _mfxLevel = v; widget.midi.sendMfx(offset: _fx.mfxLevelOffset, value: v); })),
          ]),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 1200 ? 3 : 1;
        final rows = <Widget>[];
        for (int i = 0; i < modules.length; i += cols) {
          final rowModules = modules.sublist(
            i,
            math.min(i + cols, modules.length),
          );
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int j = 0; j < rowModules.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: rowModules[j]),
              ],
              if (rowModules.length < cols)
                for (int j = rowModules.length; j < cols; j++)
                  const Expanded(child: SizedBox()),
            ],
          ));
        }
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              rows[i],
            ],
          ],
        );
      },
    );
  }

  /// Hardware module: engraved header strip (with power switch) + body.
  Widget _panel({
    required String title,
    required bool on,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    final theme = Gw7Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.surfaceHigh,
              border: Border(bottom: BorderSide(color: theme.border)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                if (_panelIcons[title] case final icon?) ...[
                  Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: Gw7Fonts.of(context).display,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                _powerSwitch(on: on, onToggle: onToggle),
              ],
            ),
          ),
          IgnorePointer(
            ignoring: !on,
            child: AnimatedOpacity(
              opacity: on ? 1.0 : 0.35,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hardware-style ON/OFF power switch with LED.
  Widget _powerSwitch({required bool on, required ValueChanged<bool> onToggle}) {
    final theme = Gw7Theme.of(context);
    return GestureDetector(
      onTap: () => onToggle(!on),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.surfaceLow,
          border: Border.all(
            color: on ? theme.tertiary : theme.border,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? theme.tertiary : theme.border,
                boxShadow: on
                    ? [BoxShadow(color: theme.tertiary.withValues(alpha: 0.6), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              on ? 'ON' : 'OFF',
              style: TextStyle(
                fontFamily: Gw7Fonts.of(context).mono,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: on ? theme.tertiary : theme.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented "type" selector rendered as a horizontal scrolling row of chips
  /// (mirroring the preset bank tabs), with inline non-interactive category
  /// labels when entries carry a `category`.
  Widget _typeRow({
    required String label,
    required List<NamedValue> types,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final items = <Widget>[];
    String? lastCategory;
    for (final t in types) {
      if (t.category != null && t.category != lastCategory) {
        items.add(_categoryItem(t.category!));
        lastCategory = t.category;
      }
      items.add(_typeChip(t: t, value: value, onChanged: onChanged));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniLabel(label),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => items[i],
          ),
        ),
      ],
    );
  }

  Widget _typeDropdown({
    required String label,
    required List<NamedValue> types,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Gw7Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MiniLabel(label),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.surfaceLow,
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: theme.textDim),
              dropdownColor: theme.surfaceHigh,
              borderRadius: BorderRadius.circular(8),
              style: TextStyle(
                fontFamily: Gw7Fonts.of(context).mono,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
              selectedItemBuilder: (context) => [
                for (final t in types)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: Gw7Fonts.of(context).mono,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.primary,
                      ),
                    ),
                  ),
              ],
              items: [
                for (final t in types)
                  DropdownMenuItem(
                    value: t.value,
                    child: Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryItem(String category) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_categoryIcons[category] case final icon?)
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            category,
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeChip({
    required NamedValue t,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final selected = t.value == value;
    final theme = Gw7Theme.of(context);
    return GestureDetector(
      onTap: () {
        onChanged(t.value);
        setState(() {});
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryContainer.withValues(alpha: 0.18)
              : theme.surfaceLow,
          border: Border.all(
            color: selected ? theme.primaryContainer : theme.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryContainer.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          t.name,
          style: TextStyle(
            fontFamily: Gw7Fonts.of(context).mono,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? theme.primary : theme.textDim,
          ),
        ),
      ),
    );
  }

  /// Stacked parameter sliders (one per line).
  Widget _sliderArea(List<_ParamSlider> sliders) {
    return Column(
      children: [
        for (int i = 0; i < sliders.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          sliders[i],
        ],
      ],
    );
  }
}

/// Slider row: label, 0–127 track, numeric readout.
class _ParamSlider extends StatelessWidget {
  const _ParamSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Gw7Theme.of(context);
    return Row(
      children: [
        SizedBox(width: 72, child: _MiniLabel(label)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: theme.primaryContainer,
              inactiveTrackColor: theme.border,
              thumbColor: theme.primary,
              overlayColor: theme.primary.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
        const SizedBox(width: 10),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: Gw7Fonts.of(context).mono,
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
