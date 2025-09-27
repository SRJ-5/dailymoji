import 'package:dailymoji/domain/entities/solution_context.dart';

class SolutionsDto {
  final String? id;
  final DateTime? createdAt;
  final String? cluster;
  final String? solutionId;
  final String? text;
  final String? url;
  final int? startAt;
  final int? endAt;
  final String? context;
  SolutionsDto({
    this.id,
    this.createdAt,
    this.cluster,
    this.solutionId,
    this.text,
    this.url,
    this.startAt,
    this.endAt,
    this.context,
  });

  SolutionsDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map['created_at'] ?? ''),
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

  SolutionsDto copyWith({
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
    return SolutionsDto(
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

  SolutionContext toEntity() {
    return SolutionContext(
        id: id,
        createdAt: createdAt,
        cluster: cluster,
        solutionId: solutionId,
        text: text,
        url: url,
        startAt: startAt,
        endAt: endAt,
        context: context);
  }
}
