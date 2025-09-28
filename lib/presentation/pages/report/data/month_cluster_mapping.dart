import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';

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

/// 하루(로컬 시간 기준)의 대표 이모지를 얻기 쉽게 Map<int(일), String(에셋경로)>로 변환
Map<int, String> buildEmojiMapByDay(List<ClusterScore> dailyMax) {
  final map = <int, String>{};
  for (final row in dailyMax) {
    final local = row.createdAt.toLocal(); // KST 등 로컬 기준
    final day = local.day; // 1~31
    map[day] = clusterToAssetPath(row.cluster);
  }
  return map;
}
