class ClusterScore {
  final String userId;
  final DateTime createdAt;
  final String cluster;
  final double score;

  ClusterScore({
    required this.userId,
    required this.createdAt,
    required this.cluster,
    required this.score,
  });
}
