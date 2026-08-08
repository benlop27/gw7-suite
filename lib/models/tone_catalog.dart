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

class NamedValue {
  final int value;
  final String name;
  final String? category;

  const NamedValue({required this.value, required this.name, this.category});

  factory NamedValue.fromJson(Map<String, dynamic> json) => NamedValue(
        value: (json['value'] as num).toInt(),
        name: json['name'] as String,
        category: json['category'] as String?,
      );
}

class EffectInfo {
  final List<NamedValue> reverbTypes;
  final List<NamedValue> chorusTypes;
  final List<NamedValue> mfxTypes;
  final List<MfxFeature> mfxFeatures;
  final int mfxBalanceOffset;
  final int mfxLevelOffset;

  const EffectInfo({
    required this.reverbTypes,
    required this.chorusTypes,
    required this.mfxTypes,
    required this.mfxFeatures,
    required this.mfxBalanceOffset,
    required this.mfxLevelOffset,
  });
}

class MfxFeature {
  final String name;
  final int offset;

  const MfxFeature({required this.name, required this.offset});
}

class ToneCatalog {
  final List<ToneBank> banks;
  final EffectInfo effects;

  const ToneCatalog({required this.banks, required this.effects});

  factory ToneCatalog.fromJson(Map<String, dynamic> json) {
    final global = (json['global'] as Map<String, dynamic>?) ?? const {};
    final reverb = (global['reverb'] as Map<String, dynamic>?) ?? const {};
    final chorus = (global['chorus'] as Map<String, dynamic>?) ?? const {};
    final mfx = (json['mfx'] as Map<String, dynamic>?) ?? const {};
    final features = (mfx['features'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((f) {
      final off = f['offset'];
      return MfxFeature(
        name: f['name'] as String,
        offset: off is num ? off.toInt() : -1,
      );
    })
        .toList();
    int? offOf(String name) {
      for (final f in features) {
        if (f.name == name && f.offset >= 0) return f.offset;
      }
      return null;
    }

    return ToneCatalog(
      banks: (json['tone_banks'] as List<dynamic>)
          .map((b) => ToneBank.fromJson(b as Map<String, dynamic>))
          .toList(),
      effects: EffectInfo(
        reverbTypes: _namedValues(reverb['types']),
        chorusTypes: _namedValues(chorus['types']),
        mfxTypes: _namedValues(mfx['types']),
        mfxFeatures: features,
        mfxBalanceOffset: offOf('balance') ?? 0x12,
        mfxLevelOffset: offOf('level') ?? 0x16,
      ),
    );
  }

  static List<NamedValue> _namedValues(dynamic raw) {
    if (raw is Map) {
      final out = <NamedValue>[];
      raw.forEach((k, v) => out.add(NamedValue(
            value: (v as num).toInt(),
            name: k.toString(),
          )));
      return out..sort((a, b) => a.value.compareTo(b.value));
    }
    if (raw is List) {
      final out = raw
          .whereType<Map<String, dynamic>>()
          .map((e) => NamedValue.fromJson(e))
          .toList();
      return out..sort((a, b) => a.value.compareTo(b.value));
    }
    return const [];
  }

  static Future<ToneCatalog> load() async {
    final raw = await rootBundle.loadString('assets/gw7_midi_catalog.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ToneCatalog.fromJson(json);
  }
}
