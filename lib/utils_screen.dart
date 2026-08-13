import 'package:flutter/material.dart';

import 'models/gw7_styles.dart';
import 'models/tone_catalog.dart';
import 'services/app_controller.dart';
import 'services/midi_service.dart';
import 'theme/app_theme.dart';

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
    required this.controller,
  });

  final ToneCatalog catalog;
  final MidiService midi;
  final AppController controller;

  @override
  State<UtilsScreen> createState() => _UtilsScreenState();
}

class _UtilsScreenState extends State<UtilsScreen> {
  AppController get _controller => widget.controller;

  int _styleCategory = 0;
  int _styleIndex = 0;

  void _selectStyle(int idx) {
    setState(() => _styleIndex = idx);
    final style = gw7Styles[_styleCategory].styles[idx];
    widget.midi.sendStyle(style.number);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final panels = <Widget>[
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
