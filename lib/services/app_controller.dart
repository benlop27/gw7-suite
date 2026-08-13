import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_state.dart';
import '../models/tone_catalog.dart';
import 'midi_service.dart';

/// Owns the app state (preset + effects + master volume), persists it to
/// local storage, and can push the whole state to the GW-7 in one go.
class AppController extends ChangeNotifier {
  AppController(this._midi, this._channel);

  final MidiService _midi;
  final int _channel;

  static const String _prefsKey = 'gw7.app_state.v1';

  AppState _state = AppState.defaults();
  bool _loaded = false;
  Timer? _saveTimer;

  AppState get state => _state;
  bool get loaded => _loaded;
  int get channel => _channel;

  /// Channel the (upper/main) part responds on — used for the preset tone
  /// and part effect sends.
  int get presetChannel => _channel;

  /// Loads the persisted state (if any) from local storage.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        _state = AppState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Fall back to defaults on any corrupt/missing state.
    }
    _loaded = true;
    notifyListeners();
  }

  /// Persists the current state immediately (cancels any pending debounce).
  Future<void> save() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_state.toJson()));
    } catch (_) {
      // Persistence is best-effort; never crash over storage.
    }
  }

  void _mutate(AppState next) {
    _state = next;
    notifyListeners();
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      _saveTimer = null;
      save();
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- Preset

  void selectBank(int index) =>
      _mutate(_state.copyWith(presetBankIndex: index, presetToneIndex: () => null));

  void selectTone({
    required int bankIndex,
    required int toneIndex,
    required int cc00,
    required int cc32,
    required int pc,
  }) {
    _midi.sendTone(cc00: cc00, cc32: cc32, pc: pc, channel: presetChannel);
    _mutate(_state.copyWith(
      presetBankIndex: bankIndex,
      presetToneIndex: () => toneIndex,
    ));
  }

  void setMasterVolume(int value) {
    _midi.sendMasterVolume(value);
    _mutate(_state.copyWith(masterVolume: value));
  }

  // -------------------------------------------------------------- Favorites

  bool isFavorite({required int bankIndex, required int toneIndex}) =>
      _state.favoritePresets
          .any((f) => f.bankIndex == bankIndex && f.toneIndex == toneIndex);

  /// Adds/removes a preset from the Stage-tab favourites.
  void toggleFavorite({required int bankIndex, required int toneIndex}) {
    final current = _state.favoritePresets;
    final exists = current
        .any((f) => f.bankIndex == bankIndex && f.toneIndex == toneIndex);
    final next = exists
        ? current
            .where((f) =>
                !(f.bankIndex == bankIndex && f.toneIndex == toneIndex))
            .toList()
        : [...current, PresetRef(bankIndex, toneIndex)];
    _mutate(_state.copyWith(favoritePresets: next));
  }

  /// Selects a preset from the Stage tab: sends the tone and records it as
  /// the current preset (so the Presets tab stays in sync).
  void selectPreset(int bankIndex, int toneIndex, ToneCatalog catalog) {
    final bank = catalog.banks[bankIndex];
    final tone = bank.tones[toneIndex];
    selectTone(
      bankIndex: bankIndex,
      toneIndex: toneIndex,
      cc00: tone.cc00,
      cc32: tone.cc32,
      pc: tone.pc,
    );
  }

  // --------------------------------------------------------- Stage quick CCs

  void _sendCc(int cc, int value) =>
      _midi.sendCc(cc: cc, value: value, channel: presetChannel);

  void setCcAttack(int value) {
    _sendCc(73, value);
    _mutate(_state.copyWith(ccAttack: value));
  }

  void setCcRelease(int value) {
    _sendCc(72, value);
    _mutate(_state.copyWith(ccRelease: value));
  }

  void setCcReverb(int value) {
    _sendCc(91, value);
    _mutate(_state.copyWith(ccReverb: value));
  }

  void setCcChorus(int value) {
    _sendCc(93, value);
    _mutate(_state.copyWith(ccChorus: value));
  }

  void setCcExpr(int value) {
    _sendCc(11, value);
    _mutate(_state.copyWith(ccExpr: value));
  }

  void setCcPan(int value) {
    _sendCc(10, value);
    _mutate(_state.copyWith(ccPan: value));
  }

  // ----------------------------------------------------------------- Reverb

  void setReverbOn(bool on) {
    _midi.sendPartReverbSend(
      channel: presetChannel,
      value: on ? AppState.reverbSend : 0,
    );
    if (on) {
      _sendReverbParams();
    }
    _mutate(_state.copyWith(reverbOn: on));
  }

  void setReverbType(int value) {
    _midi.sendReverb(param: MidiService.reverbMacro, value: value);
    _mutate(_state.copyWith(reverbType: value));
  }

  void setReverbTime(int value) {
    _midi.sendReverb(param: MidiService.reverbTime, value: value);
    _mutate(_state.copyWith(reverbTime: value));
  }

  void setReverbLevel(int value) {
    _midi.sendReverb(param: MidiService.reverbLevel, value: value);
    _mutate(_state.copyWith(reverbLevel: value));
  }

  void setReverbPredelay(int value) {
    _midi.sendReverb(param: MidiService.reverbPredelay, value: value);
    _mutate(_state.copyWith(reverbPredelay: value));
  }

  void _sendReverbParams() {
    _midi.sendReverb(param: MidiService.reverbMacro, value: _state.reverbType);
    _midi.sendReverb(param: MidiService.reverbTime, value: _state.reverbTime);
    _midi.sendReverb(param: MidiService.reverbLevel, value: _state.reverbLevel);
    _midi.sendReverb(
      param: MidiService.reverbPredelay,
      value: _state.reverbPredelay,
    );
  }

  // ----------------------------------------------------------------- Chorus

  void setChorusOn(bool on) {
    _midi.sendPartChorusSend(
      channel: presetChannel,
      value: on ? _state.chorusSend : 0,
    );
    if (on) {
      _sendChorusParams();
    }
    _mutate(_state.copyWith(chorusOn: on));
  }

  void setChorusType(int value) {
    _midi.sendChorus(param: MidiService.chorusMacro, value: value);
    _mutate(_state.copyWith(chorusType: value));
  }

  void setChorusRate(int value) {
    _midi.sendChorus(param: MidiService.chorusRate, value: value);
    _mutate(_state.copyWith(chorusRate: value));
  }

  void setChorusDepth(int value) {
    _midi.sendChorus(param: MidiService.chorusDepth, value: value);
    _mutate(_state.copyWith(chorusDepth: value));
  }

  void setChorusFeedback(int value) {
    _midi.sendChorus(param: MidiService.chorusFeedback, value: value);
    _mutate(_state.copyWith(chorusFeedback: value));
  }

  void setChorusLevel(int value) {
    _midi.sendChorus(param: MidiService.chorusLevel, value: value);
    _mutate(_state.copyWith(chorusLevel: value));
  }

  /// SEND is the part chorus send (`50 1x 21`) — it routes the part into the
  /// chorus and is what makes the effect audible for that part.
  void setChorusSend(int value) {
    _midi.sendPartChorusSend(channel: presetChannel, value: value);
    _mutate(_state.copyWith(chorusSend: value));
  }

  void _sendChorusParams() {
    _midi.sendChorus(param: MidiService.chorusMacro, value: _state.chorusType);
    _midi.sendChorus(param: MidiService.chorusRate, value: _state.chorusRate);
    _midi.sendChorus(param: MidiService.chorusDepth, value: _state.chorusDepth);
    _midi.sendChorus(
      param: MidiService.chorusFeedback,
      value: _state.chorusFeedback,
    );
    _midi.sendChorus(param: MidiService.chorusLevel, value: _state.chorusLevel);
    _midi.sendPartChorusSend(channel: presetChannel, value: _state.chorusSend);
  }

  // ------------------------------------------------------------------- MFX

  void setMfxOn(bool on) {
    _midi.sendPartMfxAssign(channel: presetChannel, value: on ? 1 : 0);
    if (on) {
      _sendMfxParams();
    }
    _mutate(_state.copyWith(mfxOn: on));
  }

  void setMfxType(int value) {
    _midi.sendMfx(offset: 0x00, value: value);
    _mutate(_state.copyWith(mfxType: value));
  }

  void setMfxBalance(int value, {required int offset}) {
    _midi.sendMfx(offset: offset, value: value);
    _mutate(_state.copyWith(mfxBalance: value));
  }

  void setMfxLevel(int value, {required int offset}) {
    _midi.sendMfx(offset: offset, value: value);
    _mutate(_state.copyWith(mfxLevel: value));
  }

  void _sendMfxParams() {
    // Type is always at offset 0x00; balance/level offsets come from the
    // effects catalog and are passed in through the sync call.
  }

  // ------------------------------------------------------------------- Sync

  /// Pushes the full current state to the GW-7: tone, master volume,
  /// reverb, chorus and insertion MFX (respecting on/off).
  void syncToKeyboard(ToneCatalog catalog) {
    final s = _state;

    if (s.presetBankIndex >= 0 &&
        s.presetBankIndex < catalog.banks.length) {
      final bank = catalog.banks[s.presetBankIndex];
      final tone = s.presetToneIndex != null &&
              s.presetToneIndex! < bank.tones.length
          ? bank.tones[s.presetToneIndex!]
          : null;
      if (tone != null) {
        _midi.sendTone(
          cc00: tone.cc00,
          cc32: tone.cc32,
          pc: tone.pc,
          channel: presetChannel,
        );
      }
    }

    _midi.sendMasterVolume(s.masterVolume);

    _midi.sendCc(cc: 73, value: s.ccAttack, channel: presetChannel);
    _midi.sendCc(cc: 72, value: s.ccRelease, channel: presetChannel);
    _midi.sendCc(cc: 91, value: s.ccReverb, channel: presetChannel);
    _midi.sendCc(cc: 93, value: s.ccChorus, channel: presetChannel);
    _midi.sendCc(cc: 11, value: s.ccExpr, channel: presetChannel);
    _midi.sendCc(cc: 10, value: s.ccPan, channel: presetChannel);

    _midi.sendPartReverbSend(
      channel: presetChannel,
      value: s.reverbOn ? AppState.reverbSend : 0,
    );
    if (s.reverbOn) {
      _sendReverbParams();
    }

    _midi.sendPartChorusSend(
      channel: presetChannel,
      value: s.chorusOn ? s.chorusSend : 0,
    );
    if (s.chorusOn) {
      _sendChorusParams();
    }

    _midi.sendPartMfxAssign(channel: presetChannel, value: s.mfxOn ? 1 : 0);
    if (s.mfxOn) {
      _midi.sendMfx(offset: 0x00, value: s.mfxType);
      _midi.sendMfx(offset: catalog.effects.mfxBalanceOffset, value: s.mfxBalance);
      _midi.sendMfx(offset: catalog.effects.mfxLevelOffset, value: s.mfxLevel);
    }
  }
}
