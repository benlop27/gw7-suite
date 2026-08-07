import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';

import 'package:gw7_midi/models/tone_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CCMessage/PCMessage encode GW-7 wire bytes', () {
    final cc0 = CCMessage(controller: 0, value: 8).generateData();
    final cc32 = CCMessage(controller: 32, value: 2).generateData();
    final pc = PCMessage(program: 0).generateData();
    expect(cc0, [0xB0, 0x00, 0x08]);
    expect(cc32, [0xB0, 0x20, 0x02]);
    expect(pc, [0xC0, 0x00]);
  });

  test('catalog asset parses into 23 banks with 657 tones', () async {
    final catalog = await ToneCatalog.load();
    expect(catalog.banks.length, 23);
    final total = catalog.banks.fold<int>(
      0,
      (sum, b) => sum + b.tones.length,
    );
    expect(total, 657);
  });

  test('St.Piano 1 wire sequence (bank PIANO, tone 1)', () async {
    final catalog = await ToneCatalog.load();
    final piano = catalog.banks.firstWhere((b) => b.name == 'PIANO');
    final t = piano.tones[0];
    expect(t.name, 'St.Piano 1');
    expect(t.cc00, 8);
    expect(t.cc32, 2);
    expect(t.pc, 1);
  });

  test('SitarDrone (WORLD 1) uses cc00/cc32/4 pc 0x68', () async {
    final catalog = await ToneCatalog.load();
    final world1 = catalog.banks.firstWhere((b) => b.name == 'WORLD 1');
    final t = world1.tones.firstWhere((t) => t.name == 'SitarDrone');
    expect(t.cc00, 4);
    expect(t.cc32, 4);
    expect(t.pc, 105);
  });
}
