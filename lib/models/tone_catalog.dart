import 'dart:convert';

import 'package:flutter/services.dart';

class Tone {
  final int no;
  final String name;
  final String category;
  final int pc;
  final int cc00;
  final int cc32;

  const Tone({
    required this.no,
    required this.name,
    required this.category,
    required this.pc,
    required this.cc00,
    required this.cc32,
  });

  factory Tone.fromJson(Map<String, dynamic> json) => Tone(
        no: json['no'] as int,
        name: json['name'] as String,
        category: json['category'] as String,
        pc: json['pc'] as int,
        cc00: json['cc00'] as int,
        cc32: json['cc32'] as int,
      );
}

class ToneBank {
  final String name;
  final List<Tone> tones;

  const ToneBank({required this.name, required this.tones});

  factory ToneBank.fromJson(Map<String, dynamic> json) => ToneBank(
        name: json['name'] as String,
        tones: (json['tones'] as List<dynamic>)
            .map((t) => Tone.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}

class ToneCatalog {
  final List<ToneBank> banks;

  const ToneCatalog({required this.banks});

  factory ToneCatalog.fromJson(Map<String, dynamic> json) => ToneCatalog(
        banks: (json['tone_banks'] as List<dynamic>)
            .map((b) => ToneBank.fromJson(b as Map<String, dynamic>))
            .toList(),
      );

  static Future<ToneCatalog> load() async {
    final raw = await rootBundle.loadString('assets/gw7_midi_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ToneCatalog.fromJson(json);
  }
}
