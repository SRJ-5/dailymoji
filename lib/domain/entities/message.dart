import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:uuid/uuid.dart';

class Message {
  final String? id; // 슈퍼베이스에서 자동 생성
  final String userId;
  final String content;
  final Sender sender;
  final MessageType type;
  final DateTime createdAt; // 슈퍼베이스에서 자동 생성 - nullable 제거
  final Map<String, dynamic>? proposal; // 솔루션 제안(버튼 등) 정보를 담을 필드

  final String? imageAssetPath; //채팅으로 보낼 이모지 이미지

  final String tempId; // 로컬 - DB 연동을 위해 로컬에 일단 uuid 부여

  Message({
    this.id,
    required this.userId,
    this.content = "",
    required this.sender,
    this.type = MessageType.normal, // 기본값 설정
    this.proposal,
    DateTime? createdAt,
    this.imageAssetPath,
    String? tempId,
  })  : createdAt = createdAt ?? DateTime.now(),
        tempId = tempId ?? const Uuid().v4();

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
    String? tempId,
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
      tempId: tempId ?? this.tempId,
    );
  }

// 객체 비교를 위한 코드!!!
  // 채팅 메시지가 앱에서 생성한 메시지는 아직 id 가 없어서
  //db에 저장된 메시지랑 다른 것으로 판단해버렸대 하,,
  // DB ID가 있으면 ID로, 없으면 임시 ID로 비교
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          (id != null ? id == other.id : tempId == other.tempId);

  @override
  int get hashCode => (id ?? tempId).hashCode;
}
