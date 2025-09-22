import 'package:dailymoji/domain/entities/survey_response.dart';

class ServeyResponseDto {
  final String? id;
  final String? userId;
  final DateTime? createdAt;
  final Map<String, dynamic>? onboardingScores;

  ServeyResponseDto({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.onboardingScores,
  });

  ServeyResponseDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          userId: map["user_id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          onboardingScores: map['onboarding_scores'] ?? {},
        );

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "created_at": createdAt?.toIso8601String(),
      "onboarding_scores": onboardingScores
    };
  }

  ServeyResponseDto copyWith(
      {String? id,
      String? userId,
      DateTime? createdAt,
      Map<String, dynamic>? onboardingScores}) {
    return ServeyResponseDto(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        createdAt: createdAt ?? this.createdAt,
        onboardingScores:
            onboardingScores ?? this.onboardingScores);
  }

  SurveyResponse toEntity() {
    return SurveyResponse(
        id: id,
        createdAt: createdAt ?? DateTime.now(),
        userId: userId ?? "",
        onboardingScores: onboardingScores);
  }

  ServeyResponseDto.fromEntity(SurveyResponse surveyResponse)
      : this(
          id: surveyResponse.id,
          createdAt: surveyResponse.createdAt,
          userId: surveyResponse.userId,
          onboardingScores: surveyResponse.onboardingScores,
        );
}
