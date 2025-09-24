// lib/domain/entities/emotional_record.dart
// 감정 분석 결과의 핵심 비즈니스 모델
// 0924 변경:
// 1. 백엔드에서 생성된 분석/제안 텍스트를 담을 필드 추가
// 2. toSummaryMessage() 메서드를 제거하고 analysisText 필드를 사용하도록 변경

class EmotionalRecord {
  final Map<String, double> finalScores;
  final double gScore;
  final int profile;
  final String? sessionId;

  // 백엔드 응답에서 직접 받을 텍스트 필드
  final String? interventionPresetId;
  final String? empathyText; // 공감 추가 (분석 결과 말하기전에 상황 이해하고 공감해주기)
  final String? analysisText; // 예: "평소보다 우울해 보여요..."
  final String? proposalText; // 예: "기분 전환을 위해... 해볼까요?"
  final String? topCluster;

  final Map<String, dynamic> intervention; // 기타 솔루션 데이터 (solution_id 등)

  EmotionalRecord({
    required this.finalScores,
    required this.gScore,
    required this.profile,
    this.sessionId,
    this.interventionPresetId,
    this.empathyText,
    this.analysisText,
    this.proposalText,
    this.topCluster,
    this.intervention = const {},
  });
}
