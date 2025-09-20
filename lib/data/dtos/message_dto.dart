import "package:dailymoji/domain/entities/message.dart";

class MessageDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? content;
  final String? sender;
  final String? type;

  MessageDto({
    this.id,
    this.createdAt,
    this.userId,
    this.content,
    this.sender,
    this.type,
  });

  MessageDto.fromJson(Map<String, dynamic> map)
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
      "user_id": userId,
      "content": content,
      "sender": sender,
      "type": type,
    };
  }

  MessageDto copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? content,
    String? sender,
    String? type,
  }) {
    return MessageDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      type: type ?? this.type,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      createdAt: createdAt ?? DateTime.now(),
      userId: userId ?? "",
      content: content ?? "",
      sender: sender == "user" ? Sender.user : Sender.bot,
      type: type == "solution" ? MessageType.solution : MessageType.normal,
    );
  }

  MessageDto.fromEntity(Message message)
      : this(
          id: message.id,
          createdAt: message.createdAt,
          userId: message.userId,
          content: message.content,
          sender: message.sender == Sender.user ? "user" : "bot",
          type: message.type == MessageType.solution ? "solution" : "normal",
        );
}
