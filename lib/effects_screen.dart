import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/tone_catalog.dart';
import 'services/midi_service.dart';

class EffectsScreen extends StatefulWidget {
  const EffectsScreen({super.key, required this.catalog, required this.midi});

  final ToneCatalog catalog;
  final MidiService midi;

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
  int _chorusSend = 0;

  int _mfxType = 0;
  int _mfxBalance = 0;
  int _mfxLevel = 0;

  int _part = 0;

  void _sendReverb(int param, int value) =>
      widget.midi.sendReverb(param: param, value: value);

  void _sendChorus(int param, int value) =>
      widget.midi.sendChorus(param: param, value: value);

  void _setReverbOn(bool on) {
    setState(() => _reverbOn = on);
    widget.midi.sendPartReverbSend(channel: _part, value: on ? _reverbSend : 0);
    if (on) {
      _sendReverb(0, _reverbType);
      _sendReverb(1, _reverbTime);
    }
  }

  void _setChorusOn(bool on) {
    setState(() => _chorusOn = on);
    widget.midi.sendPartChorusSend(channel: _part, value: on ? _chorusSend : 0);
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
    widget.midi.sendPartMfxAssign(channel: _part, value: on ? 1 : 0);
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
          _knobArea([
            _Knob(label: 'TIME', value: _reverbTime,
              onChanged: (v) { _reverbTime = v; _sendReverb(1, v); }),
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
          _knobArea([
            _Knob(label: 'RATE', value: _chorusRate,
              onChanged: (v) { _chorusRate = v; _sendChorus(1, v); }),
            _Knob(label: 'DEPTH', value: _chorusDepth,
              onChanged: (v) { _chorusDepth = v; _sendChorus(2, v); }),
            _Knob(label: 'FEEDBACK', value: _chorusFeedback,
              onChanged: (v) { _chorusFeedback = v; _sendChorus(3, v); }),
            _Knob(label: 'SEND', value: _chorusSend,
              onChanged: (v) { _chorusSend = v; _sendChorus(4, v); }),
          ]),
        ],
      ),
      _panel(
        title: 'INSERTION MFX',
        on: _mfxOn,
        onToggle: _setMfxOn,
        children: [
          _typeRow(label: 'TYPE', types: _fx.mfxTypes, value: _mfxType,
            onChanged: (v) { _mfxType = v; widget.midi.sendMfx(offset: 0x00, value: v); }),
          _knobArea([
            _Knob(label: 'BALANCE', value: _mfxBalance,
              onChanged: (v) { _mfxBalance = v; widget.midi.sendMfx(offset: _fx.mfxBalanceOffset, value: v); }),
            _Knob(label: 'LEVEL', value: _mfxLevel,
              onChanged: (v) { _mfxLevel = v; widget.midi.sendMfx(offset: _fx.mfxLevelOffset, value: v); }),
          ]),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _partStrip(),
            const SizedBox(height: 12),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < modules.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: modules[i]),
                  ],
                ],
              )
            else ...[
              for (int i = 0; i < modules.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                modules[i],
              ],
            ],
          ],
        );
      },
    );
  }

  /// Part selector shown above the effect modules.
  Widget _partStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        border: Border.all(color: const Color(0xFF2E2E2E)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const _MiniLabel('ROUTING PART'),
          const SizedBox(width: 12),
          _channelPicker(),
          const Spacer(),
          const _MiniLabel('MIDI CH'),
          const SizedBox(width: 6),
          Text(
            '${_part + 1}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE5E2E1),
            ),
          ),
        ],
      ),
    );
  }

  /// Hardware module: engraved header strip (with power switch) + body.
  Widget _panel({
    required String title,
    required bool on,
    required ValueChanged<bool> onToggle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        border: Border.all(color: const Color(0xFF2E2E2E)),
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
            decoration: const BoxDecoration(
              color: Color(0xFF1F1E1E),
              border: Border(bottom: BorderSide(color: Color(0xFF2E2E2E))),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                      color: Color(0xFFE5E2E1),
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
    return GestureDetector(
      onTap: () => onToggle(!on),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E),
          border: Border.all(
            color: on ? const Color(0xFF41DDC2) : const Color(0xFF333333),
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
                color: on ? const Color(0xFF41DDC2) : const Color(0xFF333333),
                boxShadow: on
                    ? const [BoxShadow(color: Color(0x9941DDC2), blurRadius: 8)]
                    : null,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              on ? 'ON' : 'OFF',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: on ? const Color(0xFF41DDC2) : const Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Segmented "type" selector rendered as labelled chips.
  Widget _typeRow({
    required String label,
    required List<NamedValue> types,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        const _MiniLabel('TYPE'),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (context, i) {
                final t = types[i];
                final selected = t.value == value;
                return GestureDetector(
                  onTap: () {
                    onChanged(t.value);
                    setState(() {});
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0x2EFF6600)
                          : const Color(0xFF0E0E0E),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFFFF6600)
                            : const Color(0xFF333333),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF6600).withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      t.name,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? const Color(0xFFFFB596)
                            : const Color(0xFF9A9A9A),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Responsive knob placement: one row for 1–2 knobs, 2×2 grid for 4.
  Widget _knobArea(List<_Knob> knobs) {
    const gap = 18.0;
    final cols = knobs.length >= 4 ? 2 : 1;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        final rows = <Widget>[];
        for (int i = 0; i < knobs.length; i += cols) {
          final rowKnobs = knobs.sublist(
            i,
            math.min(i + cols, knobs.length),
          );
          rows.add(Row(
            children: [
              for (int j = 0; j < rowKnobs.length; j++) ...[
                if (j > 0) const SizedBox(width: gap),
                Expanded(child: rowKnobs[j]),
              ],
              if (rowKnobs.length < cols)
                for (int j = rowKnobs.length; j < cols; j++)
                  const SizedBox(width: gap),
            ],
          ));
        }
        return Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              SizedBox(height: w, child: rows[i]),
            ],
          ],
        );
      },
    );
  }

  Widget _channelPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _part,
          dropdownColor: const Color(0xFF0E0E0E),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Color(0xFFE5E2E1),
          ),
          items: [
            for (int i = 0; i < 16; i++)
              DropdownMenuItem(value: i, child: Text('${i + 1}')),
          ],
          onChanged: (v) => setState(() => _part = v ?? 0),
        ),
      ),
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
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8A8A8A),
      ),
    );
  }
}

/// Rotary knob: drag up/down to change, arc shows position.
class _Knob extends StatefulWidget {
  const _Knob({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_Knob> createState() => _KnobState();
}

class _KnobState extends State<_Knob> {
  late int _dragBase = widget.value;

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    final frac = v / 127.0;
    final angle = (-135.0 + 270.0 * frac) * math.pi / 180.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onHorizontalDragStart: (_) => _dragBase = v,
          onHorizontalDragUpdate: (d) =>
              widget.onChanged((_dragBase + d.delta.dx * 1.2).round().clamp(0, 127)),
          onVerticalDragStart: (_) => _dragBase = v,
          onVerticalDragUpdate: (d) =>
              widget.onChanged((_dragBase - d.delta.dy * 1.2).round().clamp(0, 127)),
          child: CustomPaint(
            size: const Size(72, 72),
            painter: _KnobPainter(angle: angle, value: v),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$v',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFB596),
          ),
        ),
        _MiniLabel(widget.label),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  const _KnobPainter({required this.angle, required this.value});

  final double angle;
  final int value;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 6;

    // body
    final body = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF3A3838), Color(0xFF171616)],
        stops: [0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, body);

    // rim
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF3E3C3C),
    );

    // value arc (from -135deg)
    final arcRect = Rect.fromCircle(center: center, radius: radius - 8);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFF6600);
    final start = -135.0 * math.pi / 180.0;
    canvas.drawArc(
      arcRect,
      start,
      angle - start,
      false,
      arc,
    );

    // pointer line
    final pointerLen = radius - 9;
    final end = Offset(
      center.dx + math.cos(angle) * pointerLen,
      center.dy + math.sin(angle) * pointerLen,
    );
    canvas.drawLine(
      center,
      end,
      Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE5E2E1),
    );

    // centre cap
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFFE5E2E1));
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) =>
      oldDelegate.angle != angle;
}
