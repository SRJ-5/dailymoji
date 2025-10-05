import 'package:dailymoji/domain/entities/survey_response.dart';

// TODO: 온보딩 Score가 User Profile로 옮겨져서 여기는 이대로 남겨둠
// 쓰실 때 필요한게 있을까봐 남겨둡니다.
class ServeyResponseDto {
  final String? id;
  final String? userId;
  final DateTime? createdAt;

  ServeyResponseDto({
    required this.id,
    required this.userId,
    required this.createdAt,
  });

  ServeyResponseDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          userId: map["user_id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
        );

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "created_at": createdAt?.toIso8601String(),
    };
  }

  ServeyResponseDto copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
  }) {
    return ServeyResponseDto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  SurveyResponse toEntity() {
    return SurveyResponse(
      id: id,
      createdAt: createdAt ?? DateTime.now(),
      userId: userId ?? "",
    );
  }

  ServeyResponseDto.fromEntity(SurveyResponse surveyResponse)
      : this(
          id: surveyResponse.id,
          createdAt: surveyResponse.createdAt,
          userId: surveyResponse.userId,
        );
}
