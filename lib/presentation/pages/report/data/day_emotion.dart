// 달력페이지에 필요한 감정, 점수, 이미지경로 모델

class DayEmotion {
  final String cluster;
  final String assetPath;
  final double score;

  const DayEmotion({
    required this.cluster,
    required this.assetPath,
    required this.score,
  });
}
