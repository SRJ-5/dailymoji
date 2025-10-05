// lib/domain/entities/emotional_record.dart
// 감정 분석 결과의 핵심 비즈니스 모델

class EmotionalRecord {
  final Map<String, double> finalScores;
  final double gScore;
  final int profile;
  final String? sessionId;
  final Map<String, dynamic> intervention;

  EmotionalRecord({
    required this.finalScores,
    required this.gScore,
    required this.profile,
    this.sessionId,
    required this.intervention,
  });
}
