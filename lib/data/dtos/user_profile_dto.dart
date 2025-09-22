import 'package:dailymoji/domain/entities/user_profile.dart';

class UserProfileDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? userNickNm;
  final String? aiCharacter;
  final String? characterNm;
  final String? characterPersonality;

  UserProfileDto(
      {required this.id,
      required this.createdAt,
      required this.userId,
      required this.userNickNm,
      required this.aiCharacter,
      required this.characterNm,
      required this.characterPersonality});

  UserProfileDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          userId: map["user_id"],
          userNickNm: map["user_nick_nm"],
          aiCharacter: map["ai_character"],
          characterNm: map["character_nm"],
          characterPersonality: map["character_personality"],
        );

  Map<String, dynamic> toJson() {
    return {
      "created_at": createdAt?.toIso8601String(),
      "user_id": userId,
      "user_nick_nm": userNickNm,
      "ai_character": aiCharacter,
      "character_nm": characterNm,
      "character_personality": characterPersonality,
    };
  }

  UserProfileDto copyWith(
      {String? id,
      DateTime? createdAt,
      String? userId,
      String? userNickNm,
      String? aiCharacter,
      String? characterNm,
      String? characterPersonality}) {
    return UserProfileDto(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        userId: userId ?? this.userId,
        userNickNm: userNickNm ?? this.userNickNm,
        aiCharacter: aiCharacter ?? this.aiCharacter,
        characterNm: characterNm ?? this.characterNm,
        characterPersonality:
            characterPersonality ?? this.characterPersonality);
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      createdAt: createdAt ?? DateTime.now(),
      userId: userId ?? "",
      userNickNm: userNickNm,
      aiCharacter: aiCharacter,
      characterNm: characterNm,
      characterPersonality: characterPersonality,
    );
  }

  UserProfileDto.fromEntity(UserProfile surveyResponse)
      : this(
          id: surveyResponse.id,
          createdAt: surveyResponse.createdAt,
          userId: surveyResponse.userId,
          userNickNm: surveyResponse.userNickNm,
          aiCharacter: surveyResponse.aiCharacter,
          characterNm: surveyResponse.characterNm,
          characterPersonality:
              surveyResponse.characterPersonality,
        );
}
