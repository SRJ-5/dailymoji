// // lib/presentation/providers/cluster_scores_providers.dart
// import 'package:dailymoji/domain/use_cases/cluster_use_case/get_month_cluster_scores_use_case.dart';
// import 'package:dailymoji/presentation/providers/today_cluster_scores_provider.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:dailymoji/domain/entities/cluster_score.dart';

// // ── 이미 어딘가에 repo를 주입하는 Provider가 있다면 그걸 import해서 쓰세요.
// //final clusterScoresRepositoryProvider = Provider<ClusterScoresRepository>((ref) => ...);

// // 1) 유스케이스 Provider (얇게 감싸기)
// final getMonthClusterScoresUseCaseProvider =
//     Provider<GetMonthClusterScoresUseCase>((ref) {
//   final repo = ref.watch(clusterScoresRepositoryProvider);
//   return GetMonthClusterScoresUseCase(repo);
// });

// // 2) 패밀리 FutureProvider (userId/year/month 받음)
// class MonthParams {
//   final String userId;
//   final int year;
//   final int month;
//   const MonthParams(
//       {required this.userId, required this.year, required this.month});
// }

// final dailyMaxByMonthProvider = FutureProvider.autoDispose
//     .family<List<ClusterScore>, (String, int, int)>((ref, key) async {
//   final (userId, year, month) = key;
//   final uc = ref.watch(getMonthClusterScoresUseCaseProvider);
//   return uc.execute(userId: userId, year: year, month: month);
// });
