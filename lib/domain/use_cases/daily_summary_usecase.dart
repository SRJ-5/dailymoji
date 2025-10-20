import 'package:dailymoji/domain/entities/daily_summary.dart';
import 'package:dailymoji/domain/repositories/daily_summary_repository.dart';

/// 한 달치 데이터에서 '하루별 최고 점수 1건' 리스트를 그대로 돌려주는 유스케이스.
/// 레포지토리가 이미 가공(일별 최대 선별)까지 끝낸 값을 반환한다고 가정.
class DailySummaryUsecase {
  final DailySummaryRepository _repo;
  const DailySummaryUsecase(this._repo);

  Future<List<DailySummary>> execute({
    required String userId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _repo.fetchByMonthData(
      userId: userId,
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }
}
