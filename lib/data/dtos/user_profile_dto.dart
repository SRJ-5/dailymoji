import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';

class UserProfileDto {
  final String? id;
  final DateTime? createdAt;
  final String? userNickNm;
  final String? aiCharacter;
  final String? characterNm;
  final String? characterPersonality;
  final Map<String, dynamic>? onboardingScores;

  UserProfileDto({
    required this.id,
    required this.createdAt,
    required this.userNickNm,
    required this.aiCharacter,
    required this.characterNm,
    required this.characterPersonality,
    required this.onboardingScores,
  });

  UserProfileDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          userNickNm: map["user_nick_nm"],
          aiCharacter: map["ai_character"],
          characterNm: map["character_nm"],
          characterPersonality: CharacterPersonality.values
              .firstWhere(
                (e) => e.dbValue == map["character_personality"],
              )
              .label,
          onboardingScores: map['onboarding_scores'] ?? {},
        );

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_nick_nm": userNickNm,
      "ai_character": aiCharacter,
      "character_nm": characterNm,
      "character_personality": CharacterPersonality.values
          .firstWhere(
            (e) => e.label == characterPersonality,
            orElse: () => CharacterPersonality.probSolver,
          )
          .dbValue,
      "onboarding_scores": onboardingScores
    };
  }

  UserProfileDto copyWith(
      {String? id,
      DateTime? createdAt,
      String? userNickNm,
      String? aiCharacter,
      String? characterNm,
      String? characterPersonality,
      Map<String, dynamic>? onboardingScores}) {
    return UserProfileDto(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        userNickNm: userNickNm ?? this.userNickNm,
        aiCharacter: aiCharacter ?? this.aiCharacter,
        characterNm: characterNm ?? this.characterNm,
        characterPersonality: characterPersonality ?? this.characterPersonality,
        onboardingScores: onboardingScores ?? this.onboardingScores);
  }

  UserProfile toEntity() {
    return UserProfile(
        id: id,
        createdAt: createdAt ?? DateTime.now(),
        userNickNm: userNickNm,
        aiCharacter: aiCharacter,
        characterNm: characterNm,
        characterPersonality: characterPersonality,
        onboardingScores: onboardingScores);
  }

  UserProfileDto.fromEntity(UserProfile surveyResponse)
      : this(
          id: surveyResponse.id,
          createdAt: surveyResponse.createdAt,
          userNickNm: surveyResponse.userNickNm,
          aiCharacter: surveyResponse.aiCharacter,
          characterNm: surveyResponse.characterNm,
          characterPersonality: surveyResponse.characterPersonality,
          onboardingScores: surveyResponse.onboardingScores,
        );
}
