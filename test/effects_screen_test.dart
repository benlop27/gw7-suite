import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gw7_midi/models/tone_catalog.dart';
import 'package:gw7_midi/services/app_controller.dart';
import 'package:gw7_midi/services/midi_service.dart';
import 'package:gw7_midi/effects_screen.dart';
import 'package:gw7_midi/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ToneCatalog catalog;

  setUpAll(() async {
    catalog = await ToneCatalog.load();
  });

  testWidgets('effects tab shows the quick CC grid', (tester) async {
    final controller = AppController(MidiService(), 3);
    addTearDown(controller.dispose);

    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.studio.buildTheme(),
        home: Scaffold(
          body: EffectsScreen(catalog: catalog, controller: controller),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('QUICK CC'), findsOneWidget);
    for (final label in ['ATTACK', 'RELEASE', 'REVERB', 'CHORUS', 'EXPR', 'PAN']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.pump(const Duration(seconds: 11));
  });
}
