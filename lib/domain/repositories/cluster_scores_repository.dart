import 'package:dailymoji/domain/entities/cluster_score.dart';

abstract interface class ClusterScoresRepository {
  /// (기존) 오늘 데이터
  Future<List<ClusterScore>> fetchTodayClusters();

  /// (신규) userId + 날짜 범위로 한번에 로드
  Future<List<ClusterScore>> fetchRangeByUser({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  });
}
