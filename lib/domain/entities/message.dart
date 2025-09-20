enum Sender { user, bot }

enum MessageType { normal, solution }

class Message {
  final String? id; // 슈퍼베이스에서 자동 생성
  final String userId;
  final String content;
  final Sender sender;
  final MessageType type;
  final DateTime? createdAt; // 슈퍼베이스에서 자동 생성

  Message({
    this.id,
    required this.userId,
    required this.content,
    required this.sender,
    required this.type,
    this.createdAt,
  });
}
