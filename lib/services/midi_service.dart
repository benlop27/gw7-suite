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
}
