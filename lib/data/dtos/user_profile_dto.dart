import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';

class UserProfileDto {
  final String? id;
  final DateTime? createdAt;
  final String? userNickNm;
  final String? aiCharacter;
  final String? characterNm;
  final String? characterPersonality;
  final int? characterNum;
  final Map<String, dynamic>? onboardingScores;
  final Map<String, dynamic>? solutionTypeWeights; //RIN: 마음 관리 팁 유형 가중치
  final List<String>? negativeTags; // RIN: 부정적 태그

  UserProfileDto({
    this.id,
    this.createdAt,
    this.userNickNm,
    this.aiCharacter,
    this.characterNm,
    this.characterPersonality,
    this.characterNum,
    this.onboardingScores,
    this.solutionTypeWeights,
    this.negativeTags,
  });

  UserProfileDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          userNickNm: map["user_nick_nm"],
          aiCharacter: map["ai_character"],
          characterNm: map["character_nm"],
          characterPersonality: map["character_personality"] != null
              ? CharacterPersonality.values
                  .firstWhere(
                    (e) => e.dbValue == map["character_personality"],
                    orElse: () => CharacterPersonality.probSolver,
                  )
                  .myLabel
              : null,
          characterNum: map["character_personality"] != null
              ? CharacterPersonality.values
                  .firstWhere(
                    (e) => e.dbValue == map["character_personality"],
                    orElse: () => CharacterPersonality.probSolver,
                  )
                  .assetLabel
              : null,
          onboardingScores: map['onboarding_scores'] ?? {},
          solutionTypeWeights:
              map['solution_type_weights'] as Map<String, dynamic>? ??
                  {'breathing': 1.0, 'video': 1.0, 'action': 1.0},
          negativeTags: map['negative_tags'] != null
              ? List<String>.from(map['negative_tags'])
              : [],
        );

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_nick_nm": userNickNm,
      "ai_character": aiCharacter,
      "character_nm": characterNm,
      "character_personality": CharacterPersonality.values
          .firstWhere(
            (e) => e.myLabel == characterPersonality,
            orElse: () => CharacterPersonality.probSolver,
          )
          .dbValue,
      "onboarding_scores": onboardingScores,
      "solution_type_weights": solutionTypeWeights,
      "negative_tags": negativeTags,
    };
  }

  UserProfileDto copyWith({
    String? id,
    DateTime? createdAt,
    String? userNickNm,
    String? aiCharacter,
    String? characterNm,
    String? characterPersonality,
    int? characterNum,
    Map<String, dynamic>? onboardingScores,
    Map<String, dynamic>? solutionTypeWeights,
    List<String>? negativeTags,
  }) {
    return UserProfileDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userNickNm: userNickNm ?? this.userNickNm,
      aiCharacter: aiCharacter ?? this.aiCharacter,
      characterNm: characterNm ?? this.characterNm,
      characterPersonality: characterPersonality ?? this.characterPersonality,
      onboardingScores: onboardingScores ?? this.onboardingScores,
      solutionTypeWeights: solutionTypeWeights ?? this.solutionTypeWeights,
      negativeTags: negativeTags ?? this.negativeTags,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      createdAt: createdAt ?? DateTime.now(),
      userNickNm: userNickNm,
      aiCharacter: aiCharacter,
      characterNm: characterNm,
      characterPersonality: characterPersonality,
      characterNum: characterNum,
      onboardingScores: onboardingScores,
      solutionTypeWeights: (solutionTypeWeights ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      negativeTags: negativeTags ?? [],
    );
  }

  UserProfileDto.fromEntity(UserProfile userProfile)
      : this(
          id: userProfile.id,
          createdAt: userProfile.createdAt,
          userNickNm: userProfile.userNickNm,
          aiCharacter: userProfile.aiCharacter,
          characterNm: userProfile.characterNm,
          characterPersonality: userProfile.characterPersonality,
          characterNum: userProfile.characterNum,
          onboardingScores: userProfile.onboardingScores,
          solutionTypeWeights: userProfile.solutionTypeWeights,
          negativeTags: userProfile.negativeTags,
        );
}
