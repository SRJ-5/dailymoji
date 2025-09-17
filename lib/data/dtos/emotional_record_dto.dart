class EmotionalRecordDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? selectedEmotion;
  final double? intensity;
  final String? text;
  final List<String>? contextTokens;
  final Map<String, double>? modelProbs;
  final Map<String, double>? scorePerCluster;
  final double? gScore;
  final String? recommendedSolution;
  final int? solutionId;
  final List<String>? chatIds;

  EmotionalRecordDto({
    this.id,
    this.createdAt,
    this.userId,
    this.selectedEmotion,
    this.intensity,
    this.text,
    this.contextTokens,
    this.modelProbs,
    this.scorePerCluster,
    this.gScore,
    this.recommendedSolution,
    this.solutionId,
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
          contextTokens: map["context_tokens"] != null ? List<String>.from(map["context_tokens"]) : null,
          modelProbs: (map["model_probs"])?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
          scorePerCluster: (map["score_per_cluter"])?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
          gScore: (map["g_score"])?.toDouble(),
          recommendedSolution: map["recommended_solution"],
          solutionId: map["solution_id"],
          chatIds: map["chat_ids"] != null ? List<String>.from(map["chat_ids"]) : null,
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
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      selectedEmotion: selectedEmotion ?? this.selectedEmotion,
      intensity: intensity ?? this.intensity,
      text: text ?? this.text,
      contextTokens: contextTokens ?? this.contextTokens,
      modelProbs: modelProbs ?? this.modelProbs,
      scorePerCluster: scorePerCluster ?? this.scorePerCluster,
      gScore: gScore ?? this.gScore,
      recommendedSolution: recommendedSolution ?? this.recommendedSolution,
      solutionId: solutionId ?? this.solutionId,
      chatIds: chatIds ?? this.chatIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "create_at": createdAt?.toIso8601String(),
      "user_id": userId,
      "selected_emotion": selectedEmotion,
      "intensity": intensity,
      "text": text,
      "context_tokens": contextTokens,
      "model_probs": modelProbs,
      "score_per_cluter": scorePerCluster,
      "g_score": gScore,
      "recommended_solution": recommendedSolution,
      "solution_id": solutionId,
      "chat_ids": chatIds,
    };
  }
}
