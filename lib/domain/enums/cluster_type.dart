/// 클러스터 타입
/// 
/// 감정 분석 클러스터 종류를 정의
enum ClusterType {
  negHigh("neg_high"),
  negLow("neg_low"),
  positive("positive"),
  sleep("sleep"),
  adhd("ADHD");

  final String dbValue;
  const ClusterType(this.dbValue);
  
  /// 문자열로부터 ClusterType을 찾는 헬퍼 메서드
  static ClusterType fromString(String s) {
    return ClusterType.values.firstWhere(
      (e) => e.dbValue == s,
      orElse: () => ClusterType.positive,
    );
  }
}

