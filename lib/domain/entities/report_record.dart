// 리포트 표시에 최적화된 데이터 클래스
class ReportRecord {
  final DateTime date;
  final double gScore;
  final Map<String, double> allScores;

  ReportRecord({
    required this.date,
    required this.gScore,
    required this.allScores,
  });

  // 해당 날짜의 가장 지배적인 감정 클러스터 이름을 반환
  String get dominantEmotion {
    if (allScores.isEmpty) return "unknown";
    // gScore에 영향을 주지 않는 'positive'는 일단 제외하고 우세 감정 계산
    final moodScores = Map.from(allScores)..remove('positive');
    if (moodScores.isEmpty) return "positive";

    return moodScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
