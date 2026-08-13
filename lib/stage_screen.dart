import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/tone_catalog.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';

/// Stage tab: favourite presets (starred on the Presets tab) plus quick CC
/// controls — attack, release, reverb/chorus sends, expression and pan.
class StageScreen extends StatefulWidget {
  const StageScreen({
    super.key,
    required this.catalog,
    required this.controller,
  });

  final ToneCatalog catalog;
  final AppController controller;

  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  AppController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= 700) {
              final contentHeight = math.max(260.0, constraints.maxHeight - 28);
              return Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  height: contentHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _favoritesPanel(fillHeight: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        height: contentHeight,
                        child: _volumeRail(),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _volumePanel(),
                const SizedBox(height: 12),
                _favoritesPanel(),
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
    String? badge,
    required List<Widget> children,
    bool fillHeight = false,
  }) {
    final theme = Gw7Theme.of(context);
    final body = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
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
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primaryContainer.withValues(alpha: 0.15),
                      border: Border.all(color: theme.primaryContainer),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
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
          fillHeight
              ? Expanded(child: body)
              : body,
        ],
      ),
    );
  }

  Widget _favoritesPanel({bool fillHeight = false}) {
    final theme = Gw7Theme.of(context);
    final state = _controller.state;
    final favorites = <({int bankIndex, int toneIndex})>[
      for (final f in state.favoritePresets)
        if (f.bankIndex < widget.catalog.banks.length &&
            f.toneIndex < widget.catalog.banks[f.bankIndex].tones.length)
          (bankIndex: f.bankIndex, toneIndex: f.toneIndex),
    ];
    Widget favGrid() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cols = width >= 900
              ? 6
              : width >= 600
                  ? 4
                  : width >= 400
                      ? 3
                      : 2;
          return GridView.builder(
            shrinkWrap: !fillHeight,
            physics: fillHeight
                ? const AlwaysScrollableScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.5,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, i) {
              final f = favorites[i];
              return _favoriteCard(
                bankIndex: f.bankIndex,
                toneIndex: f.toneIndex,
                cardWidth: width / cols,
              );
            },
          );
        },
      );
    }

    return _panel(
      icon: Icons.star_rounded,
      title: 'FAVOURITES',
      badge: favorites.isEmpty ? null : '${favorites.length}',
      fillHeight: fillHeight,
      children: [
        if (favorites.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.surfaceLow,
              border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(Icons.star_outline_rounded,
                    size: 32, color: theme.textDim),
                const SizedBox(height: 8),
                Text(
                  'No favourites yet',
                  style: TextStyle(
                    fontFamily: Gw7Fonts.of(context).display,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap ★ on any preset in the Presets tab to pin it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: Gw7Fonts.of(context).ui,
                    fontSize: 12,
                    color: theme.textDim,
                  ),
                ),
              ],
            ),
          )
        else if (fillHeight)
          Expanded(child: favGrid())
        else
          favGrid(),
      ],
    );
  }

  Widget _favoriteCard({
    required int bankIndex,
    required int toneIndex,
    required double cardWidth,
  }) {
    final theme = Gw7Theme.of(context);
    final state = _controller.state;
    final bank = widget.catalog.banks[bankIndex];
    final tone = bank.tones[toneIndex];
    final selected = state.presetBankIndex == bankIndex &&
        state.presetToneIndex == toneIndex;
    return _Pressable(
      onTap: () => _controller.selectPreset(bankIndex, toneIndex, widget.catalog),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? theme.primaryContainer.withValues(alpha: 0.15)
              : theme.surfaceHigh,
          border: Border.all(
            color: selected ? theme.primaryContainer : theme.border,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryContainer.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bank.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: Gw7Fonts.of(context).mono,
                    fontSize: math.max(9, cardWidth / 18),
                    letterSpacing: 0.8,
                    color: theme.textDim,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tone.no}',
                  style: TextStyle(
                    fontFamily: Gw7Fonts.of(context).mono,
                    fontSize: math.max(14, cardWidth / 9),
                    fontWeight: FontWeight.w700,
                    color: selected ? theme.primary : theme.text,
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    tone.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: Gw7Fonts.of(context).ui,
                      fontSize: math.max(10, cardWidth / 14),
                      color: selected ? theme.primary : theme.textDim,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 3,
              right: 3,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _controller.toggleFavorite(
                  bankIndex: bankIndex,
                  toneIndex: toneIndex,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.star_rounded, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _volumePanel() {
    final theme = Gw7Theme.of(context);
    final value = _controller.state.masterVolume;
    return _panel(
      icon: Icons.volume_up_rounded,
      title: 'MASTER VOLUME',
      badge: '$value',
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 10,
            activeTrackColor: theme.primaryContainer,
            inactiveTrackColor: theme.border,
            thumbColor: theme.primary,
            overlayColor: theme.primary.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 127,
            onChanged: (v) => _controller.setMasterVolume(v.round()),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '$value',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _volumeRail() {
    final theme = Gw7Theme.of(context);
    final value = _controller.state.masterVolume;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            'MASTER',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: theme.textDim,
            ),
          ),
          Text(
            'VOLUME',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: theme.textDim,
            ),
          ),
          const SizedBox(height: 6),
          Icon(Icons.volume_up_rounded, size: 20, color: theme.textDim),
          const SizedBox(height: 8),
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
                  value: value.toDouble(),
                  min: 0,
                  max: 127,
                  onChanged: (v) => _controller.setMasterVolume(v.round()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: Gw7Fonts.of(context).mono,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pressable wrapper echoing the web manager's `button:active` feedback
/// (a small "push-in" on tap-down).
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _setDown(bool down) => setState(() => _down = down);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setDown(true),
      onTapUp: (_) => _setDown(false),
      onTapCancel: () => _setDown(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
