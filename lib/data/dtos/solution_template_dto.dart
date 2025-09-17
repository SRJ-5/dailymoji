class SolutionTemplateDto {
  final String? id;
  final DateTime? createdAt;
  final String? title;
  final String? description;
  final List<String>? solutionIds;
  final List<String>? tags;

  SolutionTemplateDto({
    this.id,
    this.createdAt,
    this.title,
    this.description,
    this.solutionIds,
    this.tags,
  });

  SolutionTemplateDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          title: map["title"],
          description: map["description"],
          solutionIds: map["solution_ids"] != null ? List<String>.from(map["solution_ids"]) : null,
          tags: map["tags"] != null ? List<String>.from(map["tags"]) : null,
        );

  Map<String, dynamic> toJson() {
    return {
      "created_at": createdAt?.toIso8601String(),
      "title": title,
      "description": description,
      "solution_ids": solutionIds,
      "tags": tags,
    };
  }

  SolutionTemplateDto copyWith({
    String? id,
    DateTime? createdAt,
    String? title,
    String? description,
    List<String>? solutionIds,
    List<String>? tags,
  }) {
    return SolutionTemplateDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      description: description ?? this.description,
      solutionIds: solutionIds ?? this.solutionIds,
      tags: tags ?? this.tags,
    );
  }
}
