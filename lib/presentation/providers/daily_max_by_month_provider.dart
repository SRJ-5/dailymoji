import 'package:dailymoji/presentation/providers/month_cluster_scores_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';

final dailyMaxByMonthProvider = FutureProvider.autoDispose
    .family<List<ClusterScore>, (String, int, int)>((ref, key) async {
  final (userId, year, month) = key;
  final uc = ref.watch(getMonthClusterScoresUseCaseProvider);
  return uc.execute(userId: userId, year: year, month: month);
});
