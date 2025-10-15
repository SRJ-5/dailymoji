class Srj5QuestionsDto {
  final int? id;
  final String? cluster;
  final String? questionCode;
  final String? questionText;
  final int? displayOrder;
  Srj5QuestionsDto(
      {required this.id,
      required this.cluster,
      required this.questionCode,
      required this.questionText,
      required this.displayOrder});

  Srj5QuestionsDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          cluster: map["cluster"],
          questionCode: map["question_code"],
          questionText: map["question_text"],
          displayOrder: map["display_order"],
        );
}
