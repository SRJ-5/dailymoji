class ClusterScoreDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? sessionId;
  final String? cluster;
  final double? score;

  ClusterScoreDto({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.sessionId,
    required this.cluster,
    required this.score,
  });

  factory ClusterScoreDto.fromJson(Map<String, dynamic> map) {
    return ClusterScoreDto(
      id: map["id"] as String?,
      createdAt:
          map["created_at"] != null ? DateTime.parse(map["created_at"]) : null,
      userId: map["user_id"] as String?,
      sessionId: map["session_id"] as String?,
      cluster: map["cluster"] as String?,
      score: (map["score"] is int)
          ? (map["score"] as int).toDouble()
          : map["score"] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "created_at": createdAt?.toIso8601String(),
      "user_id": userId,
      "session_id": sessionId,
      "cluster": cluster,
      "score": score,
    };
  }
}
