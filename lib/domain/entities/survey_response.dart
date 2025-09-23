// TODO: 온보딩 Score가 User Profile로 옮겨져서 여기는 이대로 남겨둠
// 쓰실 때 필요한게 있을까봐 남겨둡니다.
class SurveyResponse {
  final String? id;
  final String? userId;
  final DateTime? createdAt;

  SurveyResponse({
    required this.id,
    required this.userId,
    required this.createdAt,
  });

  SurveyResponse copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
  }) {
    return SurveyResponse(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
