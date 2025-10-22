// lib/data/dtos/assessment_history_dto.dart
class AssessmentHistoryDto {
  final int id;
  final String userId;
  final String assessmentType;
  final DateTime createdAt;
  final Map<String, num>? scores;
  final Map<String, dynamic>? rawResponses;

  AssessmentHistoryDto({
    required this.id,
    required this.userId,
    required this.assessmentType,
    required this.createdAt,
    this.scores,
    this.rawResponses,
  });

  factory AssessmentHistoryDto.fromJson(Map<String, dynamic> json) {
    final created = DateTime.parse(json['created_at'] as String).toUtc();

    Map<String, num>? castScores;
    if (json['scores'] != null) {
      final m = Map<String, dynamic>.from(json['scores'] as Map);
      castScores = m.map((k, v) => MapEntry(k, (v as num)));
    }

    Map<String, dynamic>? castRaw;
    if (json['raw_responses'] != null) {
      castRaw = Map<String, dynamic>.from(json['raw_responses'] as Map);
    }

    return AssessmentHistoryDto(
      id: (json['id'] as num).toInt(), // ← 안전
      userId: json['user_id'] as String,
      assessmentType: json['assessment_type'] as String,
      createdAt: created,
      scores: castScores,
      rawResponses: castRaw,
    );
  }
}
