class UserProfile {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? userNickNm;
  final String? aiCharacter;
  final String? characterNm;
  final String? characterPersonality;

  UserProfile(
      {required this.id,
      required this.createdAt,
      required this.userId,
      required this.userNickNm,
      required this.aiCharacter,
      required this.characterNm,
      required this.characterPersonality});

  UserProfile copyWith(
      {String? id,
      DateTime? createdAt,
      String? userId,
      String? userNickNm,
      String? aiCharacter,
      String? characterNm,
      String? characterPersonality}) {
    return UserProfile(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        userId: userId ?? this.userId,
        userNickNm: userNickNm ?? this.userNickNm,
        aiCharacter: aiCharacter ?? this.aiCharacter,
        characterNm: characterNm ?? this.characterNm,
        characterPersonality:
            characterPersonality ?? this.characterPersonality);
  }
}
