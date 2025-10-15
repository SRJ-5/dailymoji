class UserProfile {
  final String? id;
  final DateTime? createdAt;
  final String? userNickNm;
  final String? aiCharacter;
  final String? characterNm;
  final String? characterPersonality;
  final int? characterNum;
  final Map<String, dynamic>? onboardingScores;

  UserProfile({
    this.id,
    this.createdAt,
    this.userNickNm,
    this.aiCharacter,
    this.characterNm,
    this.characterPersonality,
    this.characterNum,
    this.onboardingScores,
  });

  UserProfile copyWith({
    String? id,
    DateTime? createdAt,
    String? userNickNm,
    String? aiCharacter,
    String? characterNm,
    String? characterPersonality,
    int? characterNum,
    Map<String, dynamic>? onboardingScores,
  }) {
    return UserProfile(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userNickNm: userNickNm ?? this.userNickNm,
      aiCharacter: aiCharacter ?? this.aiCharacter,
      characterNm: characterNm ?? this.characterNm,
      characterPersonality:
          characterPersonality ?? this.characterPersonality,
      characterNum: characterNum ?? this.characterNum,
      onboardingScores:
          onboardingScores ?? this.onboardingScores,
    );
  }
}
