import 'package:flutter/material.dart';

import 'models/tone_catalog.dart';
import 'preset_screen.dart';

void main() {
  runApp(const Gw7App());
}

class Gw7App extends StatelessWidget {
  const Gw7App({super.key});

  @override
  Widget build(BuildContext context) {
    const scheme = ColorScheme.dark(
      surface: Color(0xFF131313),
      surfaceContainerLowest: Color(0xFF0E0E0E),
      surfaceContainerLow: Color(0xFF201F1F),
      surfaceContainer: Color(0xFF1C1B1B),
      surfaceContainerHigh: Color(0xFF2D2D2D),
      onSurface: Color(0xFFE5E2E1),
      onSurfaceVariant: Color(0xFF8A8A8A),
      primary: Color(0xFFFFB596),
      primaryContainer: Color(0xFFFF6600),
      tertiary: Color(0xFF41DDC2),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      onPrimary: Color(0xFF3D1500),
      onPrimaryContainer: Color(0xFFFFFFFF),
    );
    return MaterialApp(
      title: 'GW-7 Presets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF131313),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodySmall: TextStyle(color: Color(0xFF8A8A8A)),
        ),
      ),
      home: const PresetScreen(),
    );
  }
}

Future<ToneCatalog> loadCatalog() => ToneCatalog.load();
