import 'package:dailymoji/domain/enums/cluster_type.dart';
import 'package:dailymoji/domain/enums/metric.dart';
import 'package:dailymoji/domain/repositories/cluster_scores_repository.dart';
import 'package:dailymoji/domain/models/cluster_stats_models.dart';

// 특정 userId의 최근 14일 데이터를 날짜별로 평균/최소/최대 점수로 변환해 리턴

class Get14DayClusterStatsUseCase {
  final ClusterScoresRepository repo;
  Get14DayClusterStatsUseCase(this.repo);

  /// 최근 14일(오래된→최신) 기준의 집계 결과를 반환합니다.
  /// - 입력: userId
  /// - 출력: FourteenDayAgg(days, series[ClusterType][Metric] => List<double>(len=14))
  Future<FourteenDayAgg> execute({required String userId}) async {
    // 1) 범위 계산 (UTC 기준: 오늘 00:00 ~ 내일 00:00, 그리고 14일 전부터)
    final now = DateTime.now().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 14)); // 포함
    final end = today.add(const Duration(days: 1)); // 미포함

    // 2) 14일 타임라인 키(자정) 생성: 길이 14 (오래된 → 최신)
    final days = List.generate(
      14,
      (i) => DateTime.utc(start.year, start.month, start.day)
          .add(Duration(days: i)),
    );

    // 3) 레포지토리에서 한 번에 로드
    final rows = await repo.fetchRangeByUser(
      userId: userId,
      startInclusive: start,
      endExclusive: end,
    ); // List<ClusterScore>

    // 4) 버킷팅: 날짜별 → 클러스터별 → 점수 리스트별로 나누기
    final Map<DateTime, Map<ClusterType, List<double>>> bucket = {};
    for (final r in rows) {
      final dayKey =
          DateTime.utc(r.createdAt.year, r.createdAt.month, r.createdAt.day);
      final cluster = ClusterType.fromString(r.cluster);
      final byCluster = bucket.putIfAbsent(dayKey, () => {});
      final list = byCluster.putIfAbsent(cluster, () => []);
      list.add(r.score);
    }

    // 5) 결과 시리즈 초기화: 각 클러스터마다 길이 14짜리 배열 만들기
    final clusters = ClusterType.values;
    final metrics = Metric.values;

    final Map<ClusterType, Map<Metric, List<double>>> series = {
      for (final c in clusters)
        c: {for (final m in metrics) m: List.filled(14, 0.0)}
    };

    double avg(List<double> v) =>
        v.reduce((a, b) => a + b) / v.length; // 평균 구하기 함수
    double min(List<double> v) =>
        v.reduce((a, b) => a < b ? a : b); // 최소값 구하기 함수
    double max(List<double> v) =>
        v.reduce((a, b) => a > b ? a : b); // 최대값 구하기 함수

    // 6) 각 날짜 인덱스별로 avg/min/max 채우기
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      final byCluster = bucket[d];

      for (final c in clusters) {
        final values = byCluster?[c] ?? const <double>[];
        if (values.isEmpty) {
          // 정책: 데이터 없으면 0.0으로 채움 (필요시 null 허용 모델로 바꿔도 됨)
          series[c]![Metric.avg]![i] = 0.0;
          series[c]![Metric.min]![i] = 0.0;
          series[c]![Metric.max]![i] = 0.0;
        } else {
          series[c]![Metric.avg]![i] = avg(values);
          series[c]![Metric.min]![i] = min(values);
          series[c]![Metric.max]![i] = max(values);
        }
      }
    }

    // 한국 시간으로 변환
    final daysKst = days.map((d) => d.add(const Duration(hours: 9))).toList();

    return FourteenDayAgg(days: daysKst, series: series);
  }
}
