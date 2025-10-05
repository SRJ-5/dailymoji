/// 지표 종류
/// 
/// 통계 데이터의 지표 타입 (평균, 최소, 최대)
enum Metric {
  avg("avg"),
  min("min"),
  max("max");

  final String value;
  const Metric(this.value);
}

