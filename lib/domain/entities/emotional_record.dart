// 감정 분석 결과의 핵심 비즈니스 모델
class EmotionalRecord {
  final Map<String, double> finalScores;
  final double gScore;
  final int profile;
  final String? interventionPresetId;

  EmotionalRecord({
    required this.finalScores,
    required this.gScore,
    required this.profile,
    this.interventionPresetId,
  });

  // 분석 결과를 요약 메시지로 변환하는 헬퍼 메서드
  String toSummaryMessage() {
    if (finalScores.isEmpty) {
      return "감정 분석 결과를 요약할 수 없어요.";
    }

    // 가장 높은 점수를 받은 감정 찾기
    final topEmotionEntry =
        finalScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    final topEmotion = topEmotionEntry.key;
    final topScore = (topEmotionEntry.value * 100).toInt();

    String emotionKorean;
    switch (topEmotion) {
      case 'neg_low':
        emotionKorean = '우울/무기력';
        break;
      case 'neg_high':
        emotionKorean = '불안/분노';
        break;
      case 'adhd_high':
        emotionKorean = '산만함';
        break;
      case 'sleep':
        emotionKorean = '수면 문제';
        break;
      case 'positive':
        emotionKorean = '긍정';
        break;
      default:
        emotionKorean = topEmotion;
    }

    return "오늘 당신의 마음에는 '$emotionKorean' 감정이 $topScore%로 가장 크게 자리 잡고 있네요.";
  }
}
