// weekly report 에서 차트그릴때 쓸 Gscore 뽑아오는 Dto

class SessionDto {
  final DateTime? createdAt;
  final String? userId;
  final double? gScore;

  SessionDto({
    this.createdAt,
    this.userId,
    this.gScore,
  });

  factory SessionDto.fromJson(Map<String, dynamic> map) {
    return SessionDto(
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      userId: map['user_id'] as String?,
      gScore: (map['g_score'] as num?)?.toDouble(),
    );
  }
}
