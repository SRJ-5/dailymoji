import 'package:dailymoji/data/data_sources/cluster_scores_data_source_impl.dart';
import 'package:dailymoji/domain/models/cluster_stats_models.dart';
import 'package:dailymoji/domain/use_cases/cluster_use_case/get_14day_cluster_scores_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dailymoji/data/repositories/cluster_scores_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SupabaseClient Provider (전역 주입)
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// DataSource Provider
final clusterScoresDataSourceProvider =
    Provider<ClusterScoresDataSourceImpl>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClusterScoresDataSourceImpl(client);
});

// Repository Provider
final clusterScoresRepositoryProvider =
    Provider<ClusterScoresRepositoryImpl>((ref) {
  final dataSource = ref.watch(clusterScoresDataSourceProvider);
  return ClusterScoresRepositoryImpl(dataSource);
});

// ADD: 14일 집계 UseCase Provider
final get14DayClusterStatsUseCaseProvider =
    Provider<Get14DayClusterStatsUseCase>((ref) {
  final repo = ref.watch(clusterScoresRepositoryProvider);
  return Get14DayClusterStatsUseCase(repo);
});

// ADD: userId를 받아 14일 집계를 불러오는 FutureProvider.family
final fourteenDayAggProvider =
    FutureProvider.family<FourteenDayAgg, String>((ref, userId) async {
  final uc = ref.watch(get14DayClusterStatsUseCaseProvider);
  return uc.execute(userId: userId);
});
