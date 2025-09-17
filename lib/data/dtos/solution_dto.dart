class SolutionDto {
  final int? id;
  final DateTime? createdAt;
  final String? combination;
  final String? solutionId;
  final String? emotion;
  final int? duration;
  final String? type;
  final String? contentUrl;

  SolutionDto({
    this.id,
    this.createdAt,
    this.combination,
    this.solutionId,
    this.emotion,
    this.duration,
    this.type,
    this.contentUrl,
  });

  SolutionDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          combination: map["combination"],
          solutionId: map["solution_id"],
          emotion: map["emotion"],
          duration: map["duration"],
          type: map["type"],
          contentUrl: map["content_url"],
        );

  Map<String, dynamic> toJson() {
    return {
      "created_at": createdAt?.toIso8601String(),
      "combination": combination,
      "solution_id": solutionId,
      "emotion": emotion,
      "duration": duration,
      "type": type,
      "content_url": contentUrl,
    };
  }

  SolutionDto copyWith({
    int? id,
    DateTime? createdAt,
    String? combination,
    String? solutionId,
    String? emotion,
    int? duration,
    String? type,
    String? contentUrl,
  }) {
    return SolutionDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      combination: combination ?? this.combination,
      solutionId: solutionId ?? this.solutionId,
      emotion: emotion ?? this.emotion,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      contentUrl: contentUrl ?? this.contentUrl,
    );
  }
}
