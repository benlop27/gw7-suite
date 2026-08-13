import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gw7_midi/models/tone_catalog.dart';
import 'package:gw7_midi/services/app_controller.dart';
import 'package:gw7_midi/services/midi_service.dart';
import 'package:gw7_midi/stage_screen.dart';
import 'package:gw7_midi/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ToneCatalog catalog;

  setUpAll(() async {
    catalog = await ToneCatalog.load();
  });

  AppController makeController() {
    final controller = AppController(MidiService(), 3);
    addTearDown(controller.dispose);
    controller.toggleFavorite(bankIndex: 0, toneIndex: 0);
    return controller;
  }

  Future<void> pumpStage(
    WidgetTester tester, {
    required AppController controller,
    Size size = const Size(1000, 800),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.studio.buildTheme(),
        home: Scaffold(
          body: StageScreen(catalog: catalog, controller: controller),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('favourites grid shows the starred tone', (tester) async {
    final controller = makeController();
    await pumpStage(tester, controller: controller);

    expect(find.text('St.Piano 1'), findsOneWidget);
    expect(find.text('PIANO'), findsWidgets);

    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('tapping a favourite selects and highlights it', (tester) async {
    final controller = makeController();
    await pumpStage(tester, controller: controller);

    await tester.tap(find.text('St.Piano 1'));
    await tester.pump();

    expect(controller.state.presetBankIndex, 0);
    expect(controller.state.presetToneIndex, 0);

    await tester.pump(const Duration(seconds: 11));
  });
}
