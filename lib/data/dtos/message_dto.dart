import "package:dailymoji/core/constants/emoji_assets.dart";
import "package:dailymoji/domain/entities/message.dart";
import 'package:dailymoji/domain/enums/enum_data.dart';

class MessageDto {
  final String? id;
  final DateTime? createdAt;
  final String? userId;
  final String? content;
  final String? sender;
  final String? type;
  final Map<String, dynamic>? proposal;
  final String? imageAssetPath;
  final String? sessionId;

  MessageDto({
    this.id,
    this.createdAt,
    this.userId,
    this.content,
    this.sender,
    this.type,
    this.proposal,
    this.imageAssetPath,
    this.sessionId,
  });
  // DB에서 받은 JSON을 DTO 객체로 변환
  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      userId: json['user_id'] as String?,
      content: json['content'] as String?,
      sender: json['sender'] as String?,
      type: json['type'] as String?,
      proposal: json['proposal'] as Map<String, dynamic>?,
      imageAssetPath: json['image_asset_path'] as String?,
      sessionId: json['session_id'] as String?,
    );
  }

  // DTO 객체를 DB에 보낼 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'content': content,
      'sender': sender,
      'type': type,
      'proposal': proposal,
      'image_asset_path': imageAssetPath,
      'session_id': sessionId,
      // id와 createdAt은 DB에서 자동 생성되므로 보내지 않음
    };
  }

  // DTO를 앱 내부에서 사용하는 Message Entity 객체로 변환
  Message toEntity() {
    // 문자열을 enum으로 변환 (dbValue 기준)
    final messageType = MessageType.values.firstWhere(
      (e) => e.dbValue == type,
      orElse: () => MessageType.normal,
    );
    final messageSender = Sender.values.firstWhere(
      (e) => e.dbValue == sender,
      orElse: () => Sender.bot,
    );

    final bool isImageType = messageType == MessageType.image;
    final String imageKey = content ?? "";

    return Message(
      id: id,
      createdAt: createdAt?.toLocal(),
      userId: userId ?? "",
      content: isImageType ? "" : (content ?? ""),
      sender: messageSender, // 변환된 enum 사용
      type: messageType, // 변환된 enum 사용
      proposal: proposal,
      imageAssetPath: isImageType ? kEmojiAssetMap[imageKey] : null,
    );
  }

  // 앱 내부의 Message Entity 객체를 DB에 저장하기 위한 DTO 객체로 변환
  factory MessageDto.fromEntity(Message message) {
    return MessageDto(
      id: message.id,
      createdAt: message.createdAt,
      userId: message.userId,
      content: message.type == MessageType.image
          ? kEmojiAssetMap.entries
              .firstWhere((e) => e.value == message.imageAssetPath,
                  orElse: () => const MapEntry('', ''))
              .key
          : message.content,
      // enum을 문자열로 변환 (dbValue 기준)
      sender: message.sender.dbValue,
      type: message.type.dbValue,
      proposal: message.proposal,
      imageAssetPath: message.imageAssetPath,
      // sessionId는 Message Entity에 없으므로 DTO 생성 시에는 null
    );
  }
}
