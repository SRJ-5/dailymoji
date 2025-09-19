import "package:dailymoji/domain/entities/chat.dart";

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

  Chat toEntity() {
    return Chat(
      id: id ?? "",
      createdAt: createdAt ?? DateTime.now(),
      userId: userId ?? "",
      content: content ?? "",
      sender: sender == "user" ? Sender.user : Sender.bot,
      type: type == "solution" ? ChatType.solution : ChatType.normal,
    );
  }

  factory ChatDto.fromEntity(Chat entity) {
    return ChatDto(
      id: entity.id,
      createdAt: entity.createdAt,
      userId: entity.userId,
      content: entity.content,
      sender: entity.sender == Sender.user ? "user" : "bot",
      type: entity.type == ChatType.solution ? "solution" : "normal",
    );
  }
}
