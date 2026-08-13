import 'package:flutter/material.dart';

/// Per-theme fonts exposed to the rest of the app.
class Gw7Fonts extends ThemeExtension<Gw7Fonts> {
  const Gw7Fonts({
    required this.ui,
    required this.display,
    required this.mono,
  });

  /// Main UI font for labels, chips, buttons.
  final String ui;

  /// Display font for headers / module titles.
  final String display;

  /// Monospace font for numeric readouts and MIDI data.
  final String mono;

  static Gw7Fonts of(BuildContext context) =>
      Theme.of(context).extension<Gw7Fonts>()!;

  @override
  Gw7Fonts copyWith({String? ui, String? display, String? mono}) => Gw7Fonts(
        ui: ui ?? this.ui,
        display: display ?? this.display,
        mono: mono ?? this.mono,
      );

  @override
  Gw7Fonts lerp(Gw7Fonts? other, double t) {
    if (other == null) return this;
    return Gw7Fonts(
      ui: t < 0.5 ? ui : other.ui,
      display: t < 0.5 ? display : other.display,
      mono: t < 0.5 ? mono : other.mono,
    );
  }
}

/// Exposes the active [AppTheme] so pages can use its semantic colors.
class Gw7Theme extends ThemeExtension<Gw7Theme> {
  const Gw7Theme(this.theme);

  final AppTheme theme;

  static Gw7Theme of(BuildContext context) =>
      Theme.of(context).extension<Gw7Theme>()!;

  Color get primary => theme.primary;
  Color get primaryContainer => theme.primaryContainer;
  Color get tertiary => theme.tertiary;
  Color get surface => theme.surface;
  Color get surfaceLow => theme.surfaceLow;
  Color get surfaceHigh => theme.surfaceHigh;
  Color get border => theme.border;
  Color get text => theme.text;
  Color get textDim => theme.textDim;

  @override
  Gw7Theme copyWith({AppTheme? theme}) => Gw7Theme(theme ?? this.theme);

  @override
  Gw7Theme lerp(Gw7Theme? other, double t) =>
      other == null ? this : Gw7Theme(t < 0.5 ? theme : other.theme);
}

class AppTheme {
  const AppTheme({
    required this.uiFont,
    required this.displayFont,
    required this.monoFont,
    required this.primary,
    required this.primaryContainer,
    required this.tertiary,
    required this.surface,
    required this.surfaceLow,
    required this.surfaceHigh,
    required this.border,
    required this.text,
    required this.textDim,
    required this.headerBg,
  });

  final String uiFont;
  final String displayFont;
  final String monoFont;
  final Color primary;
  final Color primaryContainer;
  final Color tertiary;
  final Color surface;
  final Color surfaceLow;
  final Color surfaceHigh;
  final Color border;
  final Color text;
  final Color textDim;
  final Color headerBg;

  /// Original cool palette (mint/blue on near-black surfaces).
  static const AppTheme studio = AppTheme(
    uiFont: 'Inter',
    displayFont: 'Inter',
    monoFont: 'JetBrainsMono',
    primary: Color(0xFF9BD9C8),
    primaryContainer: Color(0xFF2FA98C),
    tertiary: Color(0xFF7FB8FF),
    surface: Color(0xFF14151A),
    surfaceLow: Color(0xFF0E0F13),
    surfaceHigh: Color(0xFF20222B),
    border: Color(0xFF2E313C),
    text: Color(0xFFE8EAEF),
    textDim: Color(0xFF8E93A1),
    headerBg: Color(0xFF0B0C10),
  );

  ColorScheme get colorScheme => ColorScheme.dark(
        surface: surface,
        surfaceContainerLowest: surfaceLow,
        surfaceContainerLow: surfaceHigh,
        surfaceContainer: surfaceHigh,
        surfaceContainerHigh: border,
        onSurface: text,
        onSurfaceVariant: textDim,
        primary: primary,
        primaryContainer: primaryContainer,
        tertiary: tertiary,
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        onPrimary: const Color(0xFF3D1500),
        onPrimaryContainer: const Color(0xFFFFFFFF),
      );

  ThemeData buildTheme() => ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: surface,
        fontFamily: uiFont,
        textTheme: TextTheme(
          bodySmall: TextStyle(color: textDim),
          bodyMedium: TextStyle(color: text),
          bodyLarge: TextStyle(color: text),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: headerBg,
          indicatorColor: primaryContainer.withValues(alpha: 0.2),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontFamily: uiFont, color: textDim),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: TextStyle(fontFamily: monoFont, color: text),
        ),
        extensions: [
          Gw7Fonts(ui: uiFont, display: displayFont, mono: monoFont),
          Gw7Theme(this),
        ],
      );
}
