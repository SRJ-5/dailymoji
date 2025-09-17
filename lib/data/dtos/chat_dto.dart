class ChatDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? content;
  final String? sender;
  final String? type;

  ChatDto({
    this.id,
    this.createdAt,
    this.userId,
    this.content,
    this.sender,
    this.type,
  });

  ChatDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          userId: map["user_id"],
          content: map["content"],
          sender: map["sender"],
          type: map["type"],
        );

  Map<String, dynamic> toJson() {
    return {
      "created_at": createdAt?.toIso8601String(),
      "user_id": userId,
      "content": content,
      "sender": sender,
      "type": type,
    };
  }

  ChatDto copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? content,
    String? sender,
    String? type,
  }) {
    return ChatDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      type: type ?? this.type,
    );
  }
}
