class SolutionContext {
  final String? id;
  final DateTime? createdAt;
  final String? cluster;
  final String? solutionId;
  final String? text;
  final String? url;
  final int? startAt;
  final int? endAt;
  final String? context;
  SolutionContext({
    required this.id,
    required this.createdAt,
    required this.cluster,
    required this.solutionId,
    required this.text,
    required this.url,
    required this.startAt,
    required this.endAt,
    required this.context,
  });

  SolutionContext.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: map["created_at"],
          cluster: map["cluster"],
          solutionId: map["solution_id"],
          text: map["text"],
          url: map["url"],
          startAt: map["start_at"],
          endAt: map["end_at"],
          context: map["context"],
        );

  Map<String, dynamic> toJson() {
    return {
      "cluster": cluster,
      "solution_id": solutionId,
      "text": text,
      "url": url,
      "start_at": startAt,
      "end_at": endAt,
      "context": context,
    };
  }

  SolutionContext copyWith({
    String? id,
    DateTime? createdAt,
    String? cluster,
    String? solutionId,
    String? text,
    String? url,
    int? startAt,
    int? endAt,
    String? context,
  }) {
    return SolutionContext(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      cluster: cluster ?? this.cluster,
      solutionId: solutionId ?? this.solutionId,
      text: text ?? this.text,
      url: url ?? this.url,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      context: context ?? this.context,
    );
  }
}
