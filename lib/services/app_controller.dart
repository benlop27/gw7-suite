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
    _midi.sendTone(cc00: cc00, cc32: cc32, pc: pc, channel: _channel);
    _mutate(_state.copyWith(
      presetBankIndex: bankIndex,
      presetToneIndex: () => toneIndex,
    ));
  }

  void setMasterVolume(int value) {
    _midi.sendMasterVolume(value);
    _mutate(_state.copyWith(masterVolume: value));
  }

  // ----------------------------------------------------------------- Reverb

  void setReverbOn(bool on) {
    _midi.sendPartReverbSend(
      channel: _channel,
      value: on ? AppState.reverbSend : 0,
    );
    if (on) {
      _midi.sendReverb(param: 0, value: _state.reverbType);
      _midi.sendReverb(param: 1, value: _state.reverbTime);
    }
    _mutate(_state.copyWith(reverbOn: on));
  }

  void setReverbType(int value) {
    _midi.sendReverb(param: 0, value: value);
    _mutate(_state.copyWith(reverbType: value));
  }

  void setReverbTime(int value) {
    _midi.sendReverb(param: 1, value: value);
    _mutate(_state.copyWith(reverbTime: value));
  }

  // ----------------------------------------------------------------- Chorus

  void setChorusOn(bool on) {
    _midi.sendPartChorusSend(
      channel: _channel,
      value: on ? _state.chorusSend : 0,
    );
    if (on) {
      _sendChorusParams();
    }
    _mutate(_state.copyWith(chorusOn: on));
  }

  void setChorusType(int value) {
    _midi.sendChorus(param: 0, value: value);
    _mutate(_state.copyWith(chorusType: value));
  }

  void setChorusRate(int value) {
    _midi.sendChorus(param: 1, value: value);
    _mutate(_state.copyWith(chorusRate: value));
  }

  void setChorusDepth(int value) {
    _midi.sendChorus(param: 2, value: value);
    _mutate(_state.copyWith(chorusDepth: value));
  }

  void setChorusFeedback(int value) {
    _midi.sendChorus(param: 3, value: value);
    _mutate(_state.copyWith(chorusFeedback: value));
  }

  void setChorusSend(int value) {
    _midi.sendChorus(param: 4, value: value);
    _midi.sendPartChorusSend(channel: _channel, value: value);
    _mutate(_state.copyWith(chorusSend: value));
  }

  void _sendChorusParams() {
    _midi.sendChorus(param: 0, value: _state.chorusType);
    _midi.sendChorus(param: 1, value: _state.chorusRate);
    _midi.sendChorus(param: 2, value: _state.chorusDepth);
    _midi.sendChorus(param: 3, value: _state.chorusFeedback);
    _midi.sendChorus(param: 4, value: _state.chorusSend);
  }

  // ------------------------------------------------------------------- MFX

  void setMfxOn(bool on) {
    _midi.sendPartMfxAssign(channel: _channel, value: on ? 1 : 0);
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
          channel: _channel,
        );
      }
    }

    _midi.sendMasterVolume(s.masterVolume);

    _midi.sendPartReverbSend(
      channel: _channel,
      value: s.reverbOn ? AppState.reverbSend : 0,
    );
    if (s.reverbOn) {
      _midi.sendReverb(param: 0, value: s.reverbType);
      _midi.sendReverb(param: 1, value: s.reverbTime);
    }

    _midi.sendPartChorusSend(
      channel: _channel,
      value: s.chorusOn ? s.chorusSend : 0,
    );
    if (s.chorusOn) {
      _sendChorusParams();
    }

    _midi.sendPartMfxAssign(channel: _channel, value: s.mfxOn ? 1 : 0);
    if (s.mfxOn) {
      _midi.sendMfx(offset: 0x00, value: s.mfxType);
      _midi.sendMfx(offset: catalog.effects.mfxBalanceOffset, value: s.mfxBalance);
      _midi.sendMfx(offset: catalog.effects.mfxLevelOffset, value: s.mfxLevel);
    }
  }
}
