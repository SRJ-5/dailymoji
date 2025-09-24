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

  // Rin: 이모지를 채팅으로 보내서 채팅 말풍선에 남아있게 하려면
  // copyWith으로 데이터를 병합하도록 해야한다!
  Message copyWith({
    String? id,
    String? userId,
    String? content,
    Sender? sender,
    MessageType? type,
    DateTime? createdAt,
    Map<String, dynamic>? proposal,
    String? imageAssetPath,
  }) {
    return Message(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      proposal: proposal ?? this.proposal,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
    );
  }
}
