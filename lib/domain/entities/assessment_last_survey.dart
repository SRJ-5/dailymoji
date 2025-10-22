class AssessmentLastSurvey {
  final String userId;
  final DateTime createdAt; // UTC 권장

  const AssessmentLastSurvey({
    required this.userId,
    required this.createdAt,
  });
}
