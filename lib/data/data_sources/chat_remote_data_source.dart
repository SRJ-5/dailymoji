import 'package:dailymoji/data/dtos/chat_dto.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatDto>> fetchMessages({
    required String userId,
    int limit,
    String? cursorIso,
  });

  Future<void> insertMessage(ChatDto chat);

  void subscribeToMessages({
    required String userId,
    required void Function(ChatDto message) onNewMessage,
  });
}
