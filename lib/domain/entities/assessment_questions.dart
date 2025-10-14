class AssessmentQuestions {
  final String cluster;
  final String? clusterNM;
  final List<String> questionText;
  final List<String> questionCode;
  AssessmentQuestions(
      {required this.cluster,
      required this.questionText,
      required this.questionCode,
      this.clusterNM});
}
