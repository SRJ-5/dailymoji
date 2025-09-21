enum Sender { user, bot }

enum MessageType { normal, solution, analysis } //'분석중'상태 추가

class Message {
  final String? id; // 슈퍼베이스에서 자동 생성
  final String userId;
  final String content;
  final Sender sender;
  final MessageType type;
  final DateTime createdAt; // 슈퍼베이스에서 자동 생성 - nullable 제거

  Message({
    this.id,
    required this.userId,
    required this.content,
    required this.sender,
    this.type = MessageType.normal, // 기본값 설정
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
