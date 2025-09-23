enum Sender { user, bot }

enum MessageType { normal, solution, analysis, solutionProposal, image }

class Message {
  final String? id; // 슈퍼베이스에서 자동 생성
  final String userId;
  final String content;
  final Sender sender;
  final MessageType type;
  final DateTime createdAt; // 슈퍼베이스에서 자동 생성 - nullable 제거
  final Map<String, dynamic>? proposal; // 솔루션 제안(버튼 등) 정보를 담을 필드

  final String? imageAssetPath; //채팅으로 보낼 이모지 이미지

  Message({
    this.id,
    required this.userId,
    this.content = "",
    required this.sender,
    this.type = MessageType.normal, // 기본값 설정
    this.proposal,
    DateTime? createdAt,
    this.imageAssetPath,
  }) : createdAt = createdAt ?? DateTime.now();
}
