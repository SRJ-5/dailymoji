import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'day_emotion.dart';

String clusterToAssetPath(String cluster) {
  switch (cluster) {
    case 'neg_high':
      return AppImages.angryEmoji;
    case 'neg_low':
      return AppImages.cryingEmoji;
    case 'ADHD':
      return AppImages.shockedEmoji;
    case 'sleep':
      return AppImages.sleepingEmoji;
    case 'positive':
      return AppImages.smileEmoji;
    default:
      return "";
  }
}

/// 하루(로컬 기준) → DayEmotion(assetPath + score)
Map<int, DayEmotion> buildDayEmotionMapByDay(List<ClusterScore> dailyMax) {
  final map = <int, DayEmotion>{};
  for (final row in dailyMax) {
    final day = row.createdAt.toLocal().day; // 1~31
    final cluster = row.cluster;
    final asset = clusterToAssetPath(row.cluster);
    map[day] = DayEmotion(cluster: cluster, assetPath: asset, score: row.score);
  }
  return map;
}
