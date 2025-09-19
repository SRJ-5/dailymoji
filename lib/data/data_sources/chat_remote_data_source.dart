import 'package:dailymoji/data/dtos/chat_dto.dart';

abstract class ChatRemoteDataSource {
  // 유저 ID 기준으로 채팅 메세지 가져오기
  Future<List<ChatDto>> fetchChats(String userId);

  // 채팅 메세지 저장하기
  Future<bool> insertChat(ChatDto dto);

  // 특정 유저의 채팅 실시간 구독
  Stream<ChatDto> subscribeToChats(String userId);
}
