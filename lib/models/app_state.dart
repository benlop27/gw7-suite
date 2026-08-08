/// Serializable app state for the GW-7 controller.
///
/// Holds the preset selection (bank + tone) and the whole Effects section
/// (reverb / chorus / insertion MFX) plus the master volume. Utils-tab
/// settings are intentionally not persisted yet.
class AppState {
  AppState({
    required this.presetBankIndex,
    required this.presetToneIndex,
    required this.reverbOn,
    required this.reverbType,
    required this.reverbTime,
    required this.chorusOn,
    required this.chorusType,
    required this.chorusRate,
    required this.chorusDepth,
    required this.chorusFeedback,
    required this.chorusSend,
    required this.mfxOn,
    required this.mfxType,
    required this.mfxBalance,
    required this.mfxLevel,
    required this.masterVolume,
  });

  factory AppState.defaults() => AppState(
        presetBankIndex: 0,
        presetToneIndex: null,
        reverbOn: false,
        reverbType: 0,
        reverbTime: 0,
        chorusOn: false,
        chorusType: 0,
        chorusRate: 0,
        chorusDepth: 0,
        chorusFeedback: 0,
        chorusSend: 40,
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

  final bool reverbOn;
  final int reverbType;
  final int reverbTime;

  final bool chorusOn;
  final int chorusType;
  final int chorusRate;
  final int chorusDepth;
  final int chorusFeedback;
  final int chorusSend;

  final bool mfxOn;
  final int mfxType;
  final int mfxBalance;
  final int mfxLevel;

  final int masterVolume;

  AppState copyWith({
    int? presetBankIndex,
    int? Function()? presetToneIndex,
    bool? reverbOn,
    int? reverbType,
    int? reverbTime,
    bool? chorusOn,
    int? chorusType,
    int? chorusRate,
    int? chorusDepth,
    int? chorusFeedback,
    int? chorusSend,
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
      reverbOn: reverbOn ?? this.reverbOn,
      reverbType: reverbType ?? this.reverbType,
      reverbTime: reverbTime ?? this.reverbTime,
      chorusOn: chorusOn ?? this.chorusOn,
      chorusType: chorusType ?? this.chorusType,
      chorusRate: chorusRate ?? this.chorusRate,
      chorusDepth: chorusDepth ?? this.chorusDepth,
      chorusFeedback: chorusFeedback ?? this.chorusFeedback,
      chorusSend: chorusSend ?? this.chorusSend,
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
        'reverbOn': reverbOn,
        'reverbType': reverbType,
        'reverbTime': reverbTime,
        'chorusOn': chorusOn,
        'chorusType': chorusType,
        'chorusRate': chorusRate,
        'chorusDepth': chorusDepth,
        'chorusFeedback': chorusFeedback,
        'chorusSend': chorusSend,
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
      reverbOn: asBool('reverbOn') ?? false,
      reverbType: asInt('reverbType') ?? 0,
      reverbTime: asInt('reverbTime') ?? 0,
      chorusOn: asBool('chorusOn') ?? false,
      chorusType: asInt('chorusType') ?? 0,
      chorusRate: asInt('chorusRate') ?? 0,
      chorusDepth: asInt('chorusDepth') ?? 0,
      chorusFeedback: asInt('chorusFeedback') ?? 0,
      chorusSend: asInt('chorusSend') ?? 40,
      mfxOn: asBool('mfxOn') ?? false,
      mfxType: asInt('mfxType') ?? 0,
      mfxBalance: asInt('mfxBalance') ?? 0,
      mfxLevel: asInt('mfxLevel') ?? 0,
      masterVolume: asInt('masterVolume') ?? 100,
    );
  }
}
