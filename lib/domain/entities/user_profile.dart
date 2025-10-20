class UserProfile {
  final String? id;
  final DateTime? createdAt;
  final String? userNickNm;
  final String? aiCharacter;
  final String? characterNm;
  final String? characterPersonality;
  final int? characterNum;
  final Map<String, dynamic>? onboardingScores;
  // RIN: 마음 관리 팁 유형별 가중치. Map<유형, 가중치> 형태.
  final Map<String, double>? solutionTypeWeights;
  // RIN: 사용자가 원하지 않는 마음 관리 팁 태그 목록.
  final List<String>? negativeTags;

  UserProfile({
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

  UserProfile copyWith({
    String? id,
    DateTime? createdAt,
    String? userNickNm,
    String? aiCharacter,
    String? characterNm,
    String? characterPersonality,
    int? characterNum,
    Map<String, dynamic>? onboardingScores,
    Map<String, double>? solutionTypeWeights,
    List<String>? negativeTags,
  }) {
    return UserProfile(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userNickNm: userNickNm ?? this.userNickNm,
      aiCharacter: aiCharacter ?? this.aiCharacter,
      characterNm: characterNm ?? this.characterNm,
      characterPersonality: characterPersonality ?? this.characterPersonality,
      characterNum: characterNum ?? this.characterNum,
      onboardingScores: onboardingScores ?? this.onboardingScores,
      solutionTypeWeights: solutionTypeWeights ?? this.solutionTypeWeights,
      negativeTags: negativeTags ?? this.negativeTags,
    );
  }
}
