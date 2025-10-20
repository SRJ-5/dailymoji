import 'package:dailymoji/domain/enums/cluster_type.dart';
import 'package:dailymoji/domain/enums/metric.dart';

/// 평균/최저/최고 값
class Stats {
  final double avg;
  final double min;
  final double max;
  const Stats({required this.avg, required this.min, required this.max});
}

/// 14일 집계 결과
/// - days: 길이 14 (오래된 → 최신)
/// - series: [클러스터][지표] -> 길이 14의 값 배열
class FourteenDayAgg {
  final List<DateTime> days;
  final Map<ClusterType, Map<Metric, List<double>>> series;

  FourteenDayAgg({
    required this.days,
    required this.series,
  });

  /// 유틸: 특정 클러스터/지표를 차트용으로 꺼낼 때
  List<double> values(ClusterType c, Metric m) => series[c]![m]!;
}
