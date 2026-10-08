/// The tunable rules behind the SLA engine.
///
/// Each threshold is "the share of the allotted window that must still be left
/// before the task is called At Risk". A Critical task is warned about much
/// earlier than a Low one, which is the whole point of the priority weighting.
class SlaSettings {
  final double criticalThreshold;
  final double highThreshold;
  final double mediumThreshold;
  final double lowThreshold;
  final bool flagBlockedAsAtRisk;
  final bool warnUnder24h;

  const SlaSettings({
    this.criticalThreshold = 0.50,
    this.highThreshold = 0.40,
    this.mediumThreshold = 0.30,
    this.lowThreshold = 0.20,
    this.flagBlockedAsAtRisk = true,
    this.warnUnder24h = true,
  });

  SlaSettings copyWith({
    double? criticalThreshold,
    double? highThreshold,
    double? mediumThreshold,
    double? lowThreshold,
    bool? flagBlockedAsAtRisk,
    bool? warnUnder24h,
  }) =>
      SlaSettings(
        criticalThreshold: criticalThreshold ?? this.criticalThreshold,
        highThreshold: highThreshold ?? this.highThreshold,
        mediumThreshold: mediumThreshold ?? this.mediumThreshold,
        lowThreshold: lowThreshold ?? this.lowThreshold,
        flagBlockedAsAtRisk: flagBlockedAsAtRisk ?? this.flagBlockedAsAtRisk,
        warnUnder24h: warnUnder24h ?? this.warnUnder24h,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': 1,
        'criticalThreshold': criticalThreshold,
        'highThreshold': highThreshold,
        'mediumThreshold': mediumThreshold,
        'lowThreshold': lowThreshold,
        'flagBlockedAsAtRisk': flagBlockedAsAtRisk ? 1 : 0,
        'warnUnder24h': warnUnder24h ? 1 : 0,
      };

  factory SlaSettings.fromMap(Map<String, Object?> map) => SlaSettings(
        criticalThreshold: (map['criticalThreshold'] as num).toDouble(),
        highThreshold: (map['highThreshold'] as num).toDouble(),
        mediumThreshold: (map['mediumThreshold'] as num).toDouble(),
        lowThreshold: (map['lowThreshold'] as num).toDouble(),
        flagBlockedAsAtRisk: (map['flagBlockedAsAtRisk'] as int) == 1,
        warnUnder24h: (map['warnUnder24h'] as int) == 1,
      );
}
