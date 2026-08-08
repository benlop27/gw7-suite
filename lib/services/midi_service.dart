import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

class MidiStatus {
  final String text;
  final bool ok;
  final bool error;

  const MidiStatus._(this.text, {this.ok = false, this.error = false});

  const MidiStatus.idle() : this._('MIDI not initialised');

  const MidiStatus.ready() : this._('MIDI ready', ok: true);

  const MidiStatus.device(String name)
      : this._('Connected · $name', ok: true);

  const MidiStatus.error(String text) : this._(text, error: true);
}

class MidiService {
  final MidiCommand _midi = MidiCommand();

  MidiDevice? _device;

  /// Roland device ID used in SysEx messages (default 0x10).
  int deviceId = 0x10;

  /// Led / status state exposed to the UI.
  final ValueNotifier<MidiStatus> status = ValueNotifier(const MidiStatus.idle());

  /// Last transmit / receive summary shown in the footer.
  final ValueNotifier<String> lastMessage = ValueNotifier('');

  /// Newest received raw byte buffer (for debug/diagnostics).
  final ValueNotifier<String> lastRx = ValueNotifier('');

  Stream<MidiSetupChange>? get onSetupChanged => _midi.onMidiSetupChanged;

  Stream<MidiDataReceivedEvent>? get onDataReceived => _midi.onMidiDataReceived;

  bool get connected => _device?.connected ?? false;

  Future<List<MidiDevice>> scanDevices() async {
    final found = await _midi.devices ?? const <MidiDevice>[];
    if (found.isEmpty) {
      status.value = MidiStatus.error(
        'No MIDI devices — connect the GW-7 via USB',
      );
    }
    return found;
  }

  Future<void> connect(MidiDevice device) async {
    await _midi.connectToDevice(device);
    _device = device;
    status.value = MidiStatus.device(device.name);
  }

  void disconnect() {
    if (_device != null) {
      _midi.disconnectDevice(_device!);
      _device = null;
    }
    status.value = MidiStatus.idle();
  }

  void dispose() {
    _midi.dispose();
  }

  /// Sends CC0 (bank select MSB), CC32 (bank select LSB) then Program Change
  /// on the selected MIDI channel. [channel] is 0-based.
  void sendTone({
    required int cc00,
    required int cc32,
    required int pc,
    required int channel,
  }) {
    if (!connected || _device == null) {
      lastMessage.value = 'No MIDI output — is the GW-7 connected?';
      return;
    }
    final ch = channel & 0x0f;
    final out = Uint8List.fromList([
      0xb0 | ch, 0x00, cc00 & 0x7f,
      0xb0 | ch, 0x20, cc32 & 0x7f,
      0xc0 | ch, (pc - 1) & 0x7f,
    ]);
    _midi.sendData(out, deviceId: _device!.id);
    lastMessage.value = 'TX B0 ${_h(0)} ${_h(cc00)} · '
        'B0 ${_h(0x20)} ${_h(cc32)} · '
        'C0 ${_h(pc - 1)}  ch${channel + 1}';
  }

  String _h(int b) => '0${(b & 0xff).toRadixString(16).toUpperCase()}'.substring(1);

  /// Sends a raw MIDI SysEx message: `F0 <body> F7`.
  void sendSysEx(List<int> body) {
    if (!connected || _device == null) {
      lastMessage.value = 'No MIDI output — is the GW-7 connected?';
      return;
    }
    final out = Uint8List.fromList([0xf0, ...body, 0xf7]);
    _midi.sendData(out, deviceId: _device!.id);
    lastMessage.value = 'TX ${out.map(_h).join(' ')}';
  }

  /// Roland checksum over address + data bytes of a DT1/RQ1 payload.
  int _checksum(List<int> data) =>
      (0x80 - (data.fold<int>(0, (a, b) => a + b) & 0x7f)) & 0x7f;

  /// Universal Realtime reverb message.
  /// `F0 7F 7F 04 05 01 01 01 01 01 <pp> <vv> F7`
  void sendReverb({required int param, required int value}) {
    sendSysEx([0x7f, 0x7f, 0x04, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, param, value]);
  }

  /// Universal Realtime chorus message.
  /// `F0 7F 7F 04 05 01 01 01 01 02 <pp> <vv> F7`
  void sendChorus({required int param, required int value}) {
    sendSysEx([0x7f, 0x7f, 0x04, 0x05, 0x01, 0x01, 0x01, 0x01, 0x02, param, value]);
  }

  /// Insertion MFX parameter (DT1): `F0 41 <dev> 42 12 40 03 <off> <v> <sum> F7`
  void sendMfx({required int offset, required int value}) {
    final addr = [0x40, 0x03, offset & 0x7f];
    final body = [0x41, deviceId, 0x42, 0x12, ...addr, value & 0x7f];
    body.add(_checksum(addr + [value & 0x7f]));
    sendSysEx(body);
  }

  /// Part MFX assign (DT1): `F0 41 <dev> 42 12 40 4x 22 <v> <sum> F7`
  /// [channel] is 0-based; channel 10 (index 9) nibbles to 0.
  void sendPartMfxAssign({required int channel, required int value}) =>
      _sendPartParam(channel: channel, low: 0x22, base: 0x40, value: value);

  /// Part reverb send (DT1): `F0 41 <dev> 42 12 40 1x 22 <v> <sum> F7`
  /// [channel] is 0-based; 0 = off (mutes reverb for the part).
  void sendPartReverbSend({required int channel, required int value}) =>
      _sendPartParam(channel: channel, low: 0x22, base: 0x10, value: value);

  /// Part chorus send (DT1): `F0 41 <dev> 42 12 40 1x 21 <v> <sum> F7`
  /// [channel] is 0-based; 0 = off (mutes chorus for the part).
  void sendPartChorusSend({required int channel, required int value}) =>
      _sendPartParam(channel: channel, low: 0x21, base: 0x10, value: value);

  /// Generic part parameter DT1 write: `F0 41 <dev> 42 12 40 <bx> <low> <v> <sum> F7`
  void _sendPartParam({
    required int channel,
    required int low,
    required int base,
    required int value,
  }) {
    final x = (channel & 0x0f) == 9 ? 0 : (channel & 0x0f) + 1;
    final addr = [0x40, base | x, low];
    final body = [0x41, deviceId, 0x42, 0x12, ...addr, value & 0x7f];
    body.add(_checksum(addr + [value & 0x7f]));
    sendSysEx(body);
  }

  /// Part key range low (DT1): `40 1x 1D <v>` — lowest key that part plays.
  void sendPartKeyRangeLow({required int channel, required int note}) =>
      _sendPartParam(channel: channel, low: 0x1d, base: 0x10, value: note);

  /// Part key range high (DT1): `40 1x 1E <v>` — highest key that part plays.
  void sendPartKeyRangeHigh({required int channel, required int note}) =>
      _sendPartParam(channel: channel, low: 0x1e, base: 0x10, value: note);

  /// Part octave/key shift (DT1): `40 1x 16 <v>`; range -24..+24 semitones,
  /// encoded as `semitones + 0x40` (0x40 = 0).
  void sendPartKeyShift({required int channel, required int semitones}) {
    final clamped = semitones.clamp(-24, 24);
    _sendPartParam(
      channel: channel,
      low: 0x16,
      base: 0x10,
      value: clamped + 0x40,
    );
  }

  /// Sends a raw MIDI byte stream (used for System Realtime messages such as
  /// Start FA / Continue FB / Stop FC, and System Common like Song Select).
  void sendRaw(List<int> bytes) {
    if (!connected || _device == null) {
      lastMessage.value = 'No MIDI output — is the GW-7 connected?';
      return;
    }
    final out = Uint8List.fromList(bytes);
    _midi.sendData(out, deviceId: _device!.id);
    lastMessage.value = 'TX ${out.map(_h).join(' ')}';
  }

  /// Selects a Music Style by number (System Common Song Select `F3 <n-1>`).
  void sendStyle(int styleNumber) {
    sendRaw([0xf3, (styleNumber - 1) & 0x7f]);
  }

  /// Backing track transport: Start `FA`, Continue `FB`, Stop `FC`.
  void sendBackingStart() => sendRaw([0xfa]);

  void sendBackingContinue() => sendRaw([0xfb]);

  void sendBackingStop() => sendRaw([0xfc]);
}
