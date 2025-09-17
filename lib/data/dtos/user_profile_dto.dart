class UserProfileDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? userNickNm;
  final String? userGender;
  final String? job;
  final String? aiCharacter;
  final String? characterNm;

  UserProfileDto({
    this.id,
    this.createdAt,
    this.userId,
    this.userNickNm,
    this.userGender,
    this.job,
    this.aiCharacter,
    this.characterNm,
  });

  UserProfileDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          userId: map["user_id"],
          userNickNm: map["user_nick_nm"],
          userGender: map["user_gender"],
          job: map["job"],
          aiCharacter: map["ai_character"],
          characterNm: map["character_nm"],
        );

  Map<String, dynamic> toJson() {
    return {
      "created_at": createdAt?.toIso8601String(),
      "user_id": userId,
      "user_nick_nm": userNickNm,
      "user_gender": userGender,
      "job": job,
      "ai_character": aiCharacter,
      "character_nm": characterNm,
    };
  }

  UserProfileDto copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? userNickNm,
    String? userGender,
    String? job,
    String? aiCharacter,
    String? characterNm,
  }) {
    return UserProfileDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      userNickNm: userNickNm ?? this.userNickNm,
      userGender: userGender ?? this.userGender,
      job: job ?? this.job,
      aiCharacter: aiCharacter ?? this.aiCharacter,
      characterNm: characterNm ?? this.characterNm,
    );
  }
}
