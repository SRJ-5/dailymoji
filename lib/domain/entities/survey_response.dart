class SurveyResponse {
  final String? id;
  final String? userId;
  final DateTime? createdAt;
  final Map<String, dynamic>? onboardingScores;

  SurveyResponse({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.onboardingScores,
  });

  SurveyResponse copyWith(
      {String? id,
      String? userId,
      DateTime? createdAt,
      Map<String, dynamic>? onboardingScores}) {
    return SurveyResponse(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
        onboardingScores:
            onboardingScores ?? this.onboardingScores);
  }
}
