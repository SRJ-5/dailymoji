import "package:dailymoji/domain/entities/message.dart";

class MessageDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? content;
  final String? sender;
  final String? type;
  final Map<String, dynamic>? proposal;

  MessageDto({
    this.id,
    this.createdAt,
    this.userId,
    this.content,
    this.sender,
    this.type,
    this.proposal,
  });

  MessageDto.fromJson(Map<String, dynamic> map)
      : this(
          id: map["id"],
          createdAt: DateTime.tryParse(map["created_at"] ?? ""),
          userId: map["user_id"],
          content: map["content"],
          sender: map["sender"],
          type: map["type"],
          proposal: map["proposal"] != null
              ? Map<String, dynamic>.from(map["proposal"])
              : null,
        );

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "content": content,
      "sender": sender,
      "type": type,
      "proposal": proposal,
    };
  }

  MessageDto copyWith({
    String? id,
    DateTime? createdAt,
    String? userId,
    String? content,
    String? sender,
    String? type,
    final Map<String, dynamic>? proposal,
  }) {
    return MessageDto(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      proposal: proposal ?? this.proposal,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      createdAt: createdAt?.toLocal() ??
          DateTime.now(), // .toLocal()을 추가하여 UTC 시간을 현지 시간으로 변환!
      userId: userId ?? "",
      content: content ?? "",
      sender: sender == "user" ? Sender.user : Sender.bot,
      type: _mapTypeToEntity(type),
      proposal: proposal,
      // DTO에는 tempId가 없으므로 toEntity 시점에는 새로 생성됨
    );
  }

  MessageDto.fromEntity(Message message)
      : this(
          id: message.id,
          createdAt: message.createdAt,
          userId: message.userId,
          content: message.content,
          sender: message.sender == Sender.user ? "user" : "bot",
          type: _mapTypeFromEntity(message.type),
          proposal: message.proposal,
        );

// String -> MessageType 변환
  static MessageType _mapTypeToEntity(String? typeString) {
    switch (typeString) {
      case 'solution':
        return MessageType.solution;
      case 'analysis':
        return MessageType.analysis;
      case 'solution_proposal':
        return MessageType.solutionProposal;
      // --- 'image' 타입 추가 ---
      // 미췐 ㅠㅠ 이거때문에 이모지가 챗으로 안올라감 바보...ㅠ
      case 'image':
        return MessageType.image;
      default:
        return MessageType.normal;
    }
  }

  // MessageType -> String 변환
  static String _mapTypeFromEntity(MessageType type) {
    switch (type) {
      case MessageType.solution:
        return 'solution';
      case MessageType.analysis:
        return 'analysis';
      case MessageType.solutionProposal:
        return 'solution_proposal';
      // --- 'image' 타입 추가 ---
      case MessageType.image:
        return 'image';
      default:
        return 'normal';
    }
  }
}
