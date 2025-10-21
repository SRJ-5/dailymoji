import 'package:dailymoji/data/dtos/cluster_score_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cluster_scores_data_source.dart';

class ClusterScoresDataSourceImpl implements ClusterScoresDataSource {
  final SupabaseClient client;

  ClusterScoresDataSourceImpl(this.client);

  // 2주간의 데이터 가져오기
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

  // // RIN: 기존에는 모든 데이터를 가져왔지만, 이제는 Supabase RPC를 호출합니다.
  // // Supabase 프로젝트에 'get_daily_max_cluster_scores' 함수를 이용한 코드!
  // @override
  // Future<List<ClusterScoreDto>> fetchDailyMaxByUserAndMonth({
  //   required String userId,
  //   required int year,
  //   required int month,
  // }) async {
  //   try {
  //     final response = await client.rpc(
  //       'get_daily_max_cluster_scores',
  //       params: {
  //         'p_user_id': userId,
  //         'p_year': year,
  //         'p_month': month,
  //       },
  //     );

  //     // RPC 결과는 List<dynamic> 타입이므로, DTO로 변환합니다.
  //     final data = (response as List)
  //         .map((json) => ClusterScoreDto.fromJson(json))
  //         .toList();

  //     return data;
  //   } catch (e) {
  //     throw Exception("fetchDailyMaxByUserAndMonth RPC error: $e");
  //   }
  // }
}

//   // ───────────────────────────────────────────────────────────────────────────
//   // 1) 특정 연도/월의 "해당 사용자" 데이터만
//   // ───────────────────────────────────────────────────────────────────────────
//   @override
//   Future<List<ClusterScoreDto>> fetchByUserAndMonth({
//     required String userId,
//     required int year,
//     required int month,
//   }) async {
//     try {
//       final startOfMonthLocal = DateTime(year, month, 1);
//       final startOfNextMonthLocal = (month == 12)
//           ? DateTime(year + 1, 1, 1)
//           : DateTime(year, month + 1, 1);

//       final startIso = startOfMonthLocal.toUtc().toIso8601String();
//       final endIso = startOfNextMonthLocal.toUtc().toIso8601String();

//       final res = await client
//           .from('cluster_scores')
//           .select() // 슬림 페이로드 권장
//           .eq('user_id', userId)
//           .gte('created_at', startIso)
//           .lt('created_at', endIso)
//           .order('created_at', ascending: true);

//       return (res as List).map((e) => ClusterScoreDto.fromJson(e)).toList();
//     } catch (e) {
//       throw Exception('fetchByUserAndMonth error: $e');
//     }
//   }
// }

// // import 'package:dailymoji/data/dtos/cluster_scores.dart';
// // import 'package:supabase_flutter/supabase_flutter.dart';

// // import 'cluster_data_source.dart';

// // class ClusterDataSourceImpl implements ClusterDataSource {
// //   final SupabaseClient client;

// //   ClusterDataSourceImpl(this.client);

// //   @override
// //   Future<List<ClusterScoresDto>> fetchClusters() async {
// //     try {
// //       final response = await client
// //           .from('cluster_scores') // Supabase 테이블명
// //           .select();
// //       //.limit(10); // 필요시 limit 추가

// //       final data = (response as List)
// //           .map((json) => ClusterScoresDto.fromJson(json))
// //           .toList();

// //       return data;
// //     } catch (e) {
// //       // 에러 처리 (로깅 or throw)
// //       throw Exception("ClusterDataSourceImpl fetchMovies error: $e");
// //     }
// //   }
// // }
