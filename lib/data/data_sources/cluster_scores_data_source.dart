import 'package:dailymoji/data/dtos/cluster_score_dto.dart';

abstract interface class ClusterScoresDataSource {
  /// (기존) 오늘 데이터
  Future<List<ClusterScoreDto>> fetchTodayClusters();

  /// (신규) userId + 날짜 범위로 한번에 로드
  Future<List<ClusterScoreDto>> fetchByUserAndRange({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}
