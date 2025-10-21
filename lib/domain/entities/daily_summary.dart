class DailySummary {
  final String userId;
  final DateTime date;
  final String summaryText;
  final String topCluster;

  DailySummary({
    required this.userId,
    required this.date,
    required this.summaryText,
    required this.topCluster,
  });
}
