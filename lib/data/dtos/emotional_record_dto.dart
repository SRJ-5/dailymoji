class EmotionalRecordDto {
  final Map<String, double>? scorePerCluster;
  final double? gScore;
  final int? profile;
  final Map<String, dynamic>? intervention;
  final Map<String, dynamic>? debugLog;

  EmotionalRecordDto({
    this.scorePerCluster,
    this.gScore,
    this.recommendedSolution,
    this.solutionId,
    // TODO chat -> message 변경
    this.chatIds,
  });

  EmotionalRecordDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["create_at"] ?? ""),
          userId: map["user_id"],
          selectedEmotion: map["selected_emotion"],
          intensity: (map["intensity"])?.toDouble(),
          text: map["text"],
          contextTokens: map["context_tokens"] != null
              ? List<String>.from(map["context_tokens"])
              : null,
          modelProbs: (map["model_probs"])?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
          scorePerCluster: (map["score_per_cluter"])?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
          gScore: (map["g_score"])?.toDouble(),
          recommendedSolution: map["recommended_solution"],
          solutionId: map["solution_id"],
          chatIds: map["chat_ids"] != null
              ? List<String>.from(map["chat_ids"])
              : null,
        );

  EmotionalRecordDto copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? selectedEmotion,
    double? intensity,
    String? text,
    List<String>? contextTokens,
    Map<String, double>? modelProbs,
    Map<String, double>? scorePerCluster,
    double? gScore,
    String? recommendedSolution,
    int? solutionId,
    List<String>? chatIds,
  }) {
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
