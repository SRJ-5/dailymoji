import 'package:dailymoji/data/dtos/cluster_score_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cluster_scores_data_source.dart';

class ClusterScoresDataSourceImpl implements ClusterScoresDataSource {
  final SupabaseClient client;

  ClusterScoresDataSourceImpl(this.client);

  @override
  Future<List<ClusterScoreDto>> fetchTodayClusters() async {
    try {
      // 오늘 00:00:00
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      // 내일 00:00:00 (오늘의 끝)
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await client
          .from('cluster_scores')
          .select() // select all
          .gte('created_at', startOfDay.toIso8601String()) // 오늘 이상
          .lt('created_at', endOfDay.toIso8601String()); // 내일 미만

      final data = (response as List)
          .map((json) => ClusterScoreDto.fromJson(json))
          .toList();

      return data;
    } catch (e) {
      throw Exception("ClusterDataSourceImpl fetchMovies error: $e");
    }
  }

  @override
  Future<List<ClusterScoreDto>> fetchByUserAndRange({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final res = await client
        .from('cluster_scores')
        .select('user_id, created_at, cluster, score') // 슬림 페이로드
        .eq('user_id', userId)
        .gte('created_at', startInclusive.toIso8601String())
        .lt('created_at', endExclusive.toIso8601String())
        .order('created_at', ascending: true);

    return (res as List).map((e) => ClusterScoreDto.fromJson(e)).toList();
  }
}

// import 'package:dailymoji/data/dtos/cluster_scores.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import 'cluster_data_source.dart';

// class ClusterDataSourceImpl implements ClusterDataSource {
//   final SupabaseClient client;

//   ClusterDataSourceImpl(this.client);

//   @override
//   Future<List<ClusterScoresDto>> fetchClusters() async {
//     try {
//       final response = await client
//           .from('cluster_scores') // Supabase 테이블명
//           .select();
//       //.limit(10); // 필요시 limit 추가

//       final data = (response as List)
//           .map((json) => ClusterScoresDto.fromJson(json))
//           .toList();

//       return data;
//     } catch (e) {
//       // 에러 처리 (로깅 or throw)
//       throw Exception("ClusterDataSourceImpl fetchMovies error: $e");
//     }
//   }
// }
