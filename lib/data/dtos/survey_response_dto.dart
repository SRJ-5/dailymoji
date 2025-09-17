class ServeyResponseDto {
  final String? id;
  final String? userId;
  final DateTime? createdAt;

  ServeyResponseDto({
    this.id,
    this.userId,
    this.createdAt,
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
}
