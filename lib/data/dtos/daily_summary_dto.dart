class DailySummaryDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final DateTime? date;
  final String? summaryText;
  final String? topCluster;
  final int? topScore;

  DailySummaryDto(
      {this.id,
      this.createdAt,
      this.userId,
      this.date,
      this.summaryText,
      this.topCluster,
      this.topScore});

  factory DailySummaryDto.fromJson(Map<String, dynamic> map) {
    return DailySummaryDto(
      id: map["id"] as String?,
      createdAt:
          map["created_at"] != null ? DateTime.parse(map["created_at"]) : null,
      userId: map["user_id"] as String?,
      date: map["date"] != null ? DateTime.parse(map["date"]) : null,
      summaryText: map["summary_text"] as String?,
      topCluster: map["top_cluster"] as String?,
      topScore: map["top_score"] as int?,
    );
  }
}
