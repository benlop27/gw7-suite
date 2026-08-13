import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';

import 'package:gw7_midi/models/app_state.dart';
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

  test('effects catalog: reverb/chorus/MFX types parsed', () async {
    final catalog = await ToneCatalog.load();
    final fx = catalog.effects;
    expect(fx.reverbTypes.any((n) => n.name == 'plate' && n.value == 5), true);
    expect(fx.reverbTypes.any((n) => n.name == 'delay' && n.value == 6), true);
    expect(
      fx.chorusTypes.any((n) => n.name == 'flanger' && n.value == 5),
      true,
    );
    expect(
      fx.chorusTypes.any((n) => n.name == 'short_delay_fb' && n.value == 7),
      true,
    );
    expect(fx.mfxTypes.length, 23);
    expect(fx.mfxTypes.first.name, 'OFF');
    expect(fx.mfxTypes.first.category, 'OFF');
    expect(fx.mfxTypes.any((n) => n.name == 'STEREO EQ' && n.category == 'EQ'), true);
    expect(fx.mfxBalanceOffset, 0x12);
    expect(fx.mfxLevelOffset, 0x16);
  });

  test('AppState defaults and JSON round-trip preserve state', () {
    final d = AppState.defaults();
    expect(d.masterVolume, 100);
    expect(d.chorusSend, 40);
    expect(d.reverbType, 4);
    expect(d.reverbTime, 64);
    expect(d.reverbLevel, 64);
    expect(d.chorusType, 2);
    expect(d.chorusLevel, 64);
    expect(d.presetToneIndex, null);
    expect(d.favoritePresets, isEmpty);
    expect(d.ccAttack, 64);
    expect(d.ccRelease, 64);
    expect(d.ccReverb, 45);
    expect(d.ccChorus, 0);
    expect(d.ccExpr, 127);
    expect(d.ccPan, 64);

    final custom = d.copyWith(
      presetBankIndex: 12,
      presetToneIndex: () => 7,
      favoritePresets: const [
        PresetRef(3, 0),
        PresetRef(12, 7),
      ],
      ccAttack: 80,
      ccRelease: 40,
      ccReverb: 30,
      ccChorus: 60,
      ccExpr: 100,
      ccPan: 20,
      reverbOn: true,
      reverbType: 4,
      reverbPredelay: 20,
      chorusSend: 64,
      chorusLevel: 80,
      mfxType: 11,
      mfxBalance: 50,
      masterVolume: 80,
    );
    final round = AppState.fromJson(custom.toJson());
    expect(round.presetBankIndex, 12);
    expect(round.presetToneIndex, 7);
    expect(round.favoritePresets, [PresetRef(3, 0), PresetRef(12, 7)]);
    expect(round.ccAttack, 80);
    expect(round.ccRelease, 40);
    expect(round.ccReverb, 30);
    expect(round.ccChorus, 60);
    expect(round.ccExpr, 100);
    expect(round.ccPan, 20);
    expect(round.reverbOn, true);
    expect(round.reverbType, 4);
    expect(round.reverbPredelay, 20);
    expect(round.chorusSend, 64);
    expect(round.chorusLevel, 80);
    expect(round.mfxType, 11);
    expect(round.mfxBalance, 50);
    expect(round.masterVolume, 80);

    final cleared = round.copyWith(presetToneIndex: () => null);
    expect(cleared.presetToneIndex, null);
    expect(cleared.masterVolume, 80);
    expect(cleared.favoritePresets, [PresetRef(3, 0), PresetRef(12, 7)]);
  });
}
