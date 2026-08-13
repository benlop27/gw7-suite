/// A favourite preset, identified by catalog positions so it survives catalog
/// edits: `banks[bankIndex].tones[toneIndex]`.
class PresetRef {
  const PresetRef(this.bankIndex, this.toneIndex);

  final int bankIndex;
  final int toneIndex;

  Map<String, dynamic> toJson() => {'bank': bankIndex, 'tone': toneIndex};

  factory PresetRef.fromJson(Map<String, dynamic> json) => PresetRef(
        (json['bank'] as int?) ?? 0,
        (json['tone'] as int?) ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is PresetRef &&
      other.bankIndex == bankIndex &&
      other.toneIndex == toneIndex;

  @override
  int get hashCode => Object.hash(bankIndex, toneIndex);
}

/// Serializable app state for the GW-7 controller.
///
/// Holds the preset selection (bank + tone), stage favourites and quick CC
/// values (attack/release/expression/pan/effect sends), and the whole Effects
/// section (reverb / chorus / insertion MFX) plus the master volume.
class AppState {
  AppState({
    required this.presetBankIndex,
    required this.presetToneIndex,
    required this.favoritePresets,
    required this.ccAttack,
    required this.ccRelease,
    required this.ccReverb,
    required this.ccChorus,
    required this.ccExpr,
    required this.ccPan,
    required this.reverbOn,
    required this.reverbType,
    required this.reverbTime,
    required this.reverbLevel,
    required this.reverbPredelay,
    required this.chorusOn,
    required this.chorusType,
    required this.chorusRate,
    required this.chorusDepth,
    required this.chorusFeedback,
    required this.chorusSend,
    required this.chorusLevel,
    required this.mfxOn,
    required this.mfxType,
    required this.mfxBalance,
    required this.mfxLevel,
    required this.masterVolume,
  });

  factory AppState.defaults() => AppState(
        presetBankIndex: 0,
        presetToneIndex: null,
        favoritePresets: const [],
        ccAttack: 64,
        ccRelease: 64,
        ccReverb: 45,
        ccChorus: 0,
        ccExpr: 127,
        ccPan: 64,
        reverbOn: false,
        reverbType: 4,
        reverbTime: 64,
        reverbLevel: 64,
        reverbPredelay: 0,
        chorusOn: false,
        chorusType: 2,
        chorusRate: 3,
        chorusDepth: 19,
        chorusFeedback: 8,
        chorusSend: 40,
        chorusLevel: 64,
        mfxOn: false,
        mfxType: 0,
        mfxBalance: 0,
        mfxLevel: 0,
        masterVolume: 100,
      );

  /// Fixed part reverb send level used when REVERB is switched on.
  static const int reverbSend = 40;

  final int presetBankIndex;
  final int? presetToneIndex;

  /// Presets shown on the Stage tab (in the order they were added).
  final List<PresetRef> favoritePresets;

  /// Quick-edit CC values (Stage tab). CC73/72 filter envelope attack/release,
  /// CC91/93 GM reverb/chorus send, CC11 expression, CC10 pan.
  final int ccAttack;
  final int ccRelease;
  final int ccReverb;
  final int ccChorus;
  final int ccExpr;
  final int ccPan;

  final bool reverbOn;
  final int reverbType;
  final int reverbTime;
  final int reverbLevel;
  final int reverbPredelay;

  final bool chorusOn;
  final int chorusType;
  final int chorusRate;
  final int chorusDepth;
  final int chorusFeedback;
  final int chorusSend;
  final int chorusLevel;

  final bool mfxOn;
  final int mfxType;
  final int mfxBalance;
  final int mfxLevel;

  final int masterVolume;

  AppState copyWith({
    int? presetBankIndex,
    int? Function()? presetToneIndex,
    List<PresetRef>? favoritePresets,
    int? ccAttack,
    int? ccRelease,
    int? ccReverb,
    int? ccChorus,
    int? ccExpr,
    int? ccPan,
    bool? reverbOn,
    int? reverbType,
    int? reverbTime,
    int? reverbLevel,
    int? reverbPredelay,
    bool? chorusOn,
    int? chorusType,
    int? chorusRate,
    int? chorusDepth,
    int? chorusFeedback,
    int? chorusSend,
    int? chorusLevel,
    bool? mfxOn,
    int? mfxType,
    int? mfxBalance,
    int? mfxLevel,
    int? masterVolume,
  }) {
    return AppState(
      presetBankIndex: presetBankIndex ?? this.presetBankIndex,
      presetToneIndex:
          presetToneIndex != null ? presetToneIndex() : this.presetToneIndex,
      favoritePresets: favoritePresets ?? this.favoritePresets,
      ccAttack: ccAttack ?? this.ccAttack,
      ccRelease: ccRelease ?? this.ccRelease,
      ccReverb: ccReverb ?? this.ccReverb,
      ccChorus: ccChorus ?? this.ccChorus,
      ccExpr: ccExpr ?? this.ccExpr,
      ccPan: ccPan ?? this.ccPan,
      reverbOn: reverbOn ?? this.reverbOn,
      reverbType: reverbType ?? this.reverbType,
      reverbTime: reverbTime ?? this.reverbTime,
      reverbLevel: reverbLevel ?? this.reverbLevel,
      reverbPredelay: reverbPredelay ?? this.reverbPredelay,
      chorusOn: chorusOn ?? this.chorusOn,
      chorusType: chorusType ?? this.chorusType,
      chorusRate: chorusRate ?? this.chorusRate,
      chorusDepth: chorusDepth ?? this.chorusDepth,
      chorusFeedback: chorusFeedback ?? this.chorusFeedback,
      chorusSend: chorusSend ?? this.chorusSend,
      chorusLevel: chorusLevel ?? this.chorusLevel,
      mfxOn: mfxOn ?? this.mfxOn,
      mfxType: mfxType ?? this.mfxType,
      mfxBalance: mfxBalance ?? this.mfxBalance,
      mfxLevel: mfxLevel ?? this.mfxLevel,
      masterVolume: masterVolume ?? this.masterVolume,
    );
  }

  Map<String, dynamic> toJson() => {
        'presetBankIndex': presetBankIndex,
        'presetToneIndex': presetToneIndex,
        'favoritePresets': [
          for (final f in favoritePresets) f.toJson(),
        ],
        'ccAttack': ccAttack,
        'ccRelease': ccRelease,
        'ccReverb': ccReverb,
        'ccChorus': ccChorus,
        'ccExpr': ccExpr,
        'ccPan': ccPan,
        'reverbOn': reverbOn,
        'reverbType': reverbType,
        'reverbTime': reverbTime,
        'reverbLevel': reverbLevel,
        'reverbPredelay': reverbPredelay,
        'chorusOn': chorusOn,
        'chorusType': chorusType,
        'chorusRate': chorusRate,
        'chorusDepth': chorusDepth,
        'chorusFeedback': chorusFeedback,
        'chorusSend': chorusSend,
        'chorusLevel': chorusLevel,
        'mfxOn': mfxOn,
        'mfxType': mfxType,
        'mfxBalance': mfxBalance,
        'mfxLevel': mfxLevel,
        'masterVolume': masterVolume,
      };

  factory AppState.fromJson(Map<String, dynamic> json) {
    int? asInt(String key) => json[key] as int?;
    bool? asBool(String key) => json[key] as bool?;
    return AppState(
      presetBankIndex: asInt('presetBankIndex') ?? 0,
      presetToneIndex: asInt('presetToneIndex'),
      favoritePresets: [
        for (final f in (json['favoritePresets'] as List?) ?? const [])
          PresetRef.fromJson((f as Map).cast<String, dynamic>()),
      ],
      ccAttack: asInt('ccAttack') ?? 64,
      ccRelease: asInt('ccRelease') ?? 64,
      ccReverb: asInt('ccReverb') ?? 45,
      ccChorus: asInt('ccChorus') ?? 0,
      ccExpr: asInt('ccExpr') ?? 127,
      ccPan: asInt('ccPan') ?? 64,
      reverbOn: asBool('reverbOn') ?? false,
      reverbType: asInt('reverbType') ?? 4,
      reverbTime: asInt('reverbTime') ?? 64,
      reverbLevel: asInt('reverbLevel') ?? 64,
      reverbPredelay: asInt('reverbPredelay') ?? 0,
      chorusOn: asBool('chorusOn') ?? false,
      chorusType: asInt('chorusType') ?? 2,
      chorusRate: asInt('chorusRate') ?? 3,
      chorusDepth: asInt('chorusDepth') ?? 19,
      chorusFeedback: asInt('chorusFeedback') ?? 8,
      chorusSend: asInt('chorusSend') ?? 40,
      chorusLevel: asInt('chorusLevel') ?? 64,
      mfxOn: asBool('mfxOn') ?? false,
      mfxType: asInt('mfxType') ?? 0,
      mfxBalance: asInt('mfxBalance') ?? 0,
      mfxLevel: asInt('mfxLevel') ?? 0,
      masterVolume: asInt('masterVolume') ?? 100,
    );
  }
}
