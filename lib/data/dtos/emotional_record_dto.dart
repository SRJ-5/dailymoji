class EmotionalRecordDto {
  final Map<String, double>? scorePerCluster;
  final double? gScore;
  final int? profile;
  final Map<String, dynamic>? intervention;
  final Map<String, dynamic>? debugLog;

  EmotionalRecordDto({
    this.scorePerCluster,
    this.gScore,
    this.profile,
    this.intervention,
    this.debugLog,
  });

  factory EmotionalRecordDto.fromJson(Map<String, dynamic> json) {
    return EmotionalRecordDto(
      scorePerCluster: (json["final_scores"] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      ),
      gScore: (json["g_score"] as num?)?.toDouble(),
      profile: json["profile"],
      intervention: json["intervention"] != null
          ? Map<String, dynamic>.from(json["intervention"])
          : null,
      debugLog: json["debug_log"] != null
          ? Map<String, dynamic>.from(json["debug_log"])
          : null,
    );
  }
}
