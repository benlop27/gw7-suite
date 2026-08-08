import 'package:flutter/material.dart';

import 'effects_screen.dart';
import 'models/tone_catalog.dart';
import 'preset_screen.dart';
import 'services/midi_service.dart';

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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MidiService _midi = MidiService();
  ToneCatalog? _catalog;
  String? _loadError;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _midi.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final catalog = await ToneCatalog.load();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Catalog load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    return Scaffold(
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFFB4AB)),
                ),
              ),
            )
          : catalog == null
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: _tab,
                  children: [
                    PresetScreen(catalog: catalog, midi: _midi),
                    EffectsScreen(catalog: catalog, midi: _midi),
                  ],
                ),
      bottomNavigationBar: catalog == null
          ? null
          : NavigationBar(
              backgroundColor: const Color(0xFF0A0A0A),
              indicatorColor: const Color(0x33FF6600),
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.piano_outlined),
                  selectedIcon: Icon(Icons.piano),
                  label: 'Presets',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Effects',
                ),
              ],
            ),
    );
  }
}

Future<ToneCatalog> loadCatalog() => ToneCatalog.load();
