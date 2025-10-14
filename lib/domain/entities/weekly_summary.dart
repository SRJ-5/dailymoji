// lib/domain/entities/weekly_summary.dart

//  2주 리포트 API 응답을 위한 데이터 모델
class WeeklySummary {
  final String? overallSummary;
  final String? negLowSummary;
  final String? negHighSummary;
  final String? adhdSummary;
  final String? sleepSummary;
  final String? positiveSummary;

  WeeklySummary({
    this.overallSummary,
    this.negLowSummary,
    this.negHighSummary,
    this.adhdSummary,
    this.sleepSummary,
    this.positiveSummary,
  });

  factory WeeklySummary.fromJson(Map<String, dynamic> json) {
    return WeeklySummary(
      overallSummary: json['overall_summary'] as String?,
      negLowSummary: json['neg_low_summary'] as String?,
      negHighSummary: json['neg_high_summary'] as String?,
      adhdSummary: json['adhd_summary'] as String?,
      sleepSummary: json['sleep_summary'] as String?,
      positiveSummary: json['positive_summary'] as String?,
    );
  }
}
