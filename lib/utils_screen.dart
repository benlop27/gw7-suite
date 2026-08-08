import 'package:flutter/material.dart';

import 'models/gw7_styles.dart';
import 'models/tone_catalog.dart';
import 'services/midi_service.dart';
import 'theme/app_theme.dart';

const List<String> _noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

String _noteName(int n) =>
    '${_noteNames[n % 12]}${(n / 12).floor() - 1}';

const Map<String, IconData> _styleCategoryIcons = {
  'Rock': Icons.bolt,
  'Dance': Icons.music_note,
  '8Beat': Icons.directions_walk,
  '16Beat': Icons.album,
  'Jazz': Icons.local_cafe,
  'Latin': Icons.public,
  'Traditional': Icons.flag,
  'Ballroom': Icons.waves,
  'World': Icons.public,
};

class UtilsScreen extends StatefulWidget {
  const UtilsScreen({
    super.key,
    required this.catalog,
    required this.midi,
    required this.channel,
  });

  final ToneCatalog catalog;
  final MidiService midi;
  final int channel;

  @override
  State<UtilsScreen> createState() => _UtilsScreenState();
}

class _UtilsScreenState extends State<UtilsScreen> {
  static const int _lowerChannel = 1;

  int _mode = 0;
  int _splitPoint = 60;

  int _upperBank = 0;
  int? _upperTone;
  int _lowerBank = 0;
  int? _lowerTone;

  int _octaves = 0;

  int _styleCategory = 0;
  int _styleIndex = 0;

  int get _upperChannel => widget.channel;

  ToneBank get _upperBankData => widget.catalog.banks[_upperBank];

  ToneBank get _lowerBankData => widget.catalog.banks[_lowerBank];

  void _applyKeyboardMode() {
    final low = _splitPoint;
    if (_mode == 1) {
      widget.midi.sendPartKeyRangeLow(channel: _upperChannel, note: low);
      widget.midi.sendPartKeyRangeHigh(channel: _upperChannel, note: 127);
      widget.midi.sendPartKeyRangeLow(channel: _lowerChannel, note: 0);
      widget.midi.sendPartKeyRangeHigh(channel: _lowerChannel, note: low - 1);
    } else {
      widget.midi.sendPartKeyRangeLow(channel: _upperChannel, note: 0);
      widget.midi.sendPartKeyRangeHigh(channel: _upperChannel, note: 127);
      widget.midi.sendPartKeyRangeLow(channel: _lowerChannel, note: 0);
      widget.midi.sendPartKeyRangeHigh(channel: _lowerChannel, note: 127);
    }
  }

  void _selectUpperTone(int idx) {
    setState(() => _upperTone = idx);
    final tone = _upperBankData.tones[idx];
    widget.midi.sendTone(
      cc00: tone.cc00,
      cc32: tone.cc32,
      pc: tone.pc,
      channel: _upperChannel,
    );
  }

  void _selectLowerTone(int idx) {
    setState(() => _lowerTone = idx);
    final tone = _lowerBankData.tones[idx];
    widget.midi.sendTone(
      cc00: tone.cc00,
      cc32: tone.cc32,
      pc: tone.pc,
      channel: _lowerChannel,
    );
  }

  void _applyOctave(int octaves) {
    setState(() => _octaves = octaves);
    widget.midi.sendPartKeyShift(
      channel: _upperChannel,
      semitones: octaves * 12,
    );
    widget.midi.sendPartKeyShift(
      channel: _lowerChannel,
      semitones: octaves * 12,
    );
  }

  void _selectStyle(int idx) {
    setState(() => _styleIndex = idx);
    final style = gw7Styles[_styleCategory].styles[idx];
    widget.midi.sendStyle(style.number);
  }

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      _keyboardPanel(),
      _octavePanel(),
      _backingPanel(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1200 ? 3 : 1;
        final rows = <Widget>[];
        for (int i = 0; i < panels.length; i += cols) {
          final rowPanels = panels.sublist(
            i,
            (i + cols) > panels.length ? panels.length : i + cols,
          );
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int j = 0; j < rowPanels.length; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(child: rowPanels[j]),
              ],
              for (int j = rowPanels.length; j < cols; j++)
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

  Widget _panel({
    required IconData icon,
    required String title,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surfaceHigh,
              border: Border(bottom: BorderSide(color: theme.border)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: Gw7Fonts.of(context).display,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: Gw7Fonts.of(context).mono,
          fontSize: 10,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _keyboardPanel() {
    final theme = Gw7Theme.of(context);
    return _panel(
      icon: Icons.splitscreen,
      title: 'KEYBOARD MODE',
      children: [
        _sectionLabel('MODE'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (m, label) in const [(0, 'MAIN'), (1, 'SPLIT'), (2, 'DUAL')])
              _modeChip(label: label, active: _mode == m, onTap: () {
                setState(() => _mode = m);
                _applyKeyboardMode();
              }),
          ],
        ),
        if (_mode == 1) ...[
          const SizedBox(height: 10),
          _sectionLabel('SPLIT POINT · ${_noteName(_splitPoint)}'),
          SliderTheme(
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
              value: _splitPoint.toDouble(),
              min: 24,
              max: 96,
              divisions: 72,
              label: _noteName(_splitPoint),
              onChanged: (v) => setState(() => _splitPoint = v.round()),
              onChangeEnd: (_) => _applyKeyboardMode(),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _sectionLabel('PARTS'),
        _partPicker(
          label: 'UPPER · CH${_upperChannel + 1}',
          bankIndex: _upperBank,
          toneIndex: _upperTone,
          bank: _upperBankData,
          onBank: (i) => setState(() {
            _upperBank = i;
            _upperTone = null;
          }),
          onTone: _selectUpperTone,
        ),
        const SizedBox(height: 10),
        _partPicker(
          label: 'LOWER · CH${_lowerChannel + 1}',
          bankIndex: _lowerBank,
          toneIndex: _lowerTone,
          bank: _lowerBankData,
          onBank: (i) => setState(() {
            _lowerBank = i;
            _lowerTone = null;
          }),
          onTone: _selectLowerTone,
        ),
      ],
    );
  }

  Widget _modeChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Gw7Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? theme.primaryContainer.withValues(alpha: 0.18) : theme.surfaceLow,
          border: Border.all(
            color: active ? theme.primaryContainer : theme.border,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: Gw7Fonts.of(context).mono,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? theme.primary : theme.textDim,
          ),
        ),
      ),
    );
  }

  Widget _partPicker({
    required String label,
    required int bankIndex,
    required int? toneIndex,
    required ToneBank bank,
    required ValueChanged<int> onBank,
    required ValueChanged<int> onTone,
  }) {
    final theme = Gw7Theme.of(context);
    final tone = toneIndex != null && toneIndex < bank.tones.length
        ? bank.tones[toneIndex]
        : null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.surfaceLow,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 8),
          _dropdown(
            value: bankIndex,
            hint: 'BANK',
            items: [
              for (int i = 0; i < widget.catalog.banks.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(widget.catalog.banks[i].name),
                ),
            ],
            onChanged: (v) => onBank(v!),
          ),
          const SizedBox(height: 8),
          _dropdown(
            value: toneIndex,
            hint: 'TONE',
            items: [
              for (int i = 0; i < bank.tones.length; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    bank.tones[i].name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => onTone(v!),
          ),
          if (tone != null) ...[
            const SizedBox(height: 8),
            Text(
              '${bank.name} ${(toneIndex! + 1).toString().padLeft(3, '0')}',
              style: TextStyle(
                fontFamily: Gw7Fonts.of(context).mono,
                fontSize: 11,
                color: theme.textDim,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dropdown({
    required int? value,
    required String hint,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    final theme = Gw7Theme.of(context);
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 11,
              color: theme.textDim,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down, size: 18, color: theme.textDim),
          dropdownColor: theme.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          style: TextStyle(
            fontFamily: Gw7Fonts.of(context).mono,
            fontSize: 11,
            color: theme.text,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _octavePanel() {
    final theme = Gw7Theme.of(context);
    return _panel(
      icon: Icons.trending_up,
      title: 'OCTAVE SHIFT',
      children: [
        _sectionLabel('KEYBOARD PARTS'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int o = -2; o <= 2; o++)
              _octaveChip(
                label: o == 0 ? '0' : o > 0 ? '+$o' : '$o',
                active: _octaves == o,
                onTap: () => _applyOctave(o),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'CURRENT',
              style: TextStyle(
                fontFamily: Gw7Fonts.of(context).mono,
                fontSize: 10,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _octaves == 0
                    ? '±0 OCTAVES'
                    : _octaves > 0
                        ? '+$_octaves OCTAVE${_octaves == 1 ? '' : 'S'}'
                        : '$_octaves OCTAVES',
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
        ),
      ],
    );
  }

  Widget _octaveChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Gw7Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? theme.primaryContainer.withValues(alpha: 0.18) : theme.surfaceLow,
          border: Border.all(
            color: active ? theme.primaryContainer : theme.border,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: Gw7Fonts.of(context).mono,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? theme.primary : theme.textDim,
          ),
        ),
      ),
    );
  }

  Widget _backingPanel() {
    final theme = Gw7Theme.of(context);
    final category = gw7Styles[_styleCategory];
    return _panel(
      icon: Icons.play_arrow,
      title: 'BACKING TRACK',
      children: [
        _sectionLabel('STYLE CATEGORY'),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: gw7Styles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final c = gw7Styles[i];
              final active = i == _styleCategory;
              return GestureDetector(
                onTap: () => setState(() {
                  _styleCategory = i;
                  _styleIndex = 0;
                }),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: active
                        ? theme.primaryContainer.withValues(alpha: 0.12)
                        : theme.surfaceLow,
                    border: Border.all(
                      color: active ? theme.primaryContainer : theme.border,
                      width: active ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _styleCategoryIcons[c.name] ?? Icons.music_note,
                        size: 14,
                        color: active ? theme.primary : theme.textDim,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.name,
                        style: TextStyle(
                          fontFamily: Gw7Fonts.of(context).mono,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
        const SizedBox(height: 10),
        _sectionLabel('STYLES'),
        SizedBox(
          height: 120,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 2.6,
            ),
            itemCount: category.styles.length,
            itemBuilder: (context, i) => _styleChip(
              style: category.styles[i],
              active: i == _styleIndex,
              onTap: () => _selectStyle(i),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionLabel('TRANSPORT'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _transportButton(
              icon: Icons.play_arrow,
              label: 'START',
              onTap: widget.midi.sendBackingStart,
            ),
            _transportButton(
              icon: Icons.pause,
              label: 'STOP',
              onTap: widget.midi.sendBackingStop,
            ),
            _transportButton(
              icon: Icons.fast_forward,
              label: 'CONTINUE',
              onTap: widget.midi.sendBackingContinue,
            ),
            _transportButton(
              icon: Icons.skip_next,
              label: 'INTRO',
              onTap: () {
                widget.midi.sendStyle(category.styles[_styleIndex].number);
                widget.midi.sendBackingStart();
              },
            ),
            _transportButton(
              icon: Icons.sync,
              label: 'FILL',
              onTap: widget.midi.sendBackingContinue,
            ),
            _transportButton(
              icon: Icons.stop,
              label: 'ENDING',
              onTap: widget.midi.sendBackingStop,
            ),
          ],
        ),
      ],
    );
  }

  Widget _styleChip({
    required Gw7Style style,
    required bool active,
    required VoidCallback onTap,
  }) {
    final theme = Gw7Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? theme.primaryContainer.withValues(alpha: 0.18) : theme.surfaceLow,
          border: Border.all(
            color: active ? theme.primaryContainer : theme.border,
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              style.number.toString().padLeft(3, '0'),
              style: TextStyle(
                fontFamily: Gw7Fonts.of(context).mono,
                fontSize: 10,
                color: theme.textDim,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                style.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: Gw7Fonts.of(context).mono,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? theme.primary : theme.text,
                ),
              ),
            ),
            Text(
              '${style.tempo}',
              style: TextStyle(
                fontFamily: Gw7Fonts.of(context).mono,
                fontSize: 10,
                color: theme.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Gw7Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.surfaceLow,
          border: Border.all(color: theme.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: Gw7Fonts.of(context).mono,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: theme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
