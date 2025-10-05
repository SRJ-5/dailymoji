import 'package:dailymoji/domain/entities/cluster_score.dart';
import 'package:dailymoji/domain/repositories/cluster_scores_repository.dart';

/// 한 달치 데이터에서 '하루별 최고 점수 1건' 리스트를 그대로 돌려주는 유스케이스.
/// 레포지토리가 이미 가공(일별 최대 선별)까지 끝낸 값을 반환한다고 가정.
class GetMonthClusterScoresUseCase {
  final ClusterScoresRepository _repo;
  const GetMonthClusterScoresUseCase(this._repo);

  Future<List<ClusterScore>> execute({
    required String userId,
    required int year,
    required int month,
  }) {
    return _repo.fetchByUserAndMonth(
      userId: userId,
      year: year,
      month: month,
    );
  }
}
