import 'package:dailymoji/domain/entities/chat.dart';

abstract class ChatRepository {
  // 특정 유저의 채팅 내역 불러오기
  Future<List<Chat>> loadMessages(String userId);

  // 새로운 채팅 메시지지 전송
  Future<bool> sendMessage(Chat chat);

  // 특정 유저의 채팅 실시간 구독
  Stream<Chat> subscribeMessages(String userId);
}
