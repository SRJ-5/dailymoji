import 'package:dailymoji/data/dtos/cluster_score_dto.dart';

abstract interface class ClusterScoresDataSource {
  /// userId + 14일 내의 범위로 한번에 로드
  Future<List<ClusterScoreDto>> fetchByUserAndRange({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  });

  // RIN: 기존 fetchByUserAndMonth가 RPC 호출을 위한 새 함수로 변경되었습니다.
  Future<List<ClusterScoreDto>> fetchDailyMaxByUserAndMonth({
    // Future<List<ClusterScoreDto>> fetchByUserAndMonth({
    required String userId,
    required int year,
    required int month,
  });
}
