import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

import '../services/midi_service.dart';

void exposeWebDebug(MidiService midi) {
  if (!kIsWeb) return;
  globalContext.setProperty('gw7Debug'.toJS, (() {
    return <String, Object>{
      'lastMessage': midi.lastMessage.value,
      'status': midi.status.value.text,
    }.jsify();
  }).toJS);
}
