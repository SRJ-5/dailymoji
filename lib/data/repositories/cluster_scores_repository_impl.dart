import 'package:dailymoji/data/data_sources/cluster_scores_data_source.dart';
import 'package:dailymoji/data/dtos/cluster_score_dto.dart';
import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'package:dailymoji/domain/repositories/cluster_scores_repository.dart';

class ClusterScoresRepositoryImpl implements ClusterScoresRepository {
  final ClusterScoresDataSource dataSource;

  ClusterScoresRepositoryImpl(this.dataSource);

  @override
  Future<List<ClusterScore>> fetchTodayClusters() async {
    try {
      final List<ClusterScoreDto> dtos = await dataSource.fetchTodayClusters();

      final entities = dtos.map((dto) {
        return ClusterScore(
          createdAt: dto.createdAt ?? DateTime.now(),
          userId: dto.userId ?? '',
          cluster: dto.cluster ?? '',
          score: dto.score ?? 0.0,
        );
      }).toList();

      return entities;
    } catch (e) {
      throw Exception(
          "ClusterScoresRepositoryImpl fetchTodayClusters error: $e");
    }
  }

// (신규) 14일 집계용 범위 조회
  @override
  Future<List<ClusterScore>> fetchRangeByUser({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) async {
    final dtos = await dataSource.fetchByUserAndRange(
      userId: userId,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
    return _toEntities(dtos);
  }

  // DTO → 슬림 Entity 매핑
  List<ClusterScore> _toEntities(List<ClusterScoreDto> dtos) {
    return dtos.map((d) {
      return ClusterScore(
        userId: d.userId ?? '',
        createdAt:
            d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        cluster: d.cluster ?? '',
        score: d.score ?? 0.0,
      );
    }).toList();
  }
}
