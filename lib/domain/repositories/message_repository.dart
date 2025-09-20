import 'package:dailymoji/domain/entities/message.dart';

abstract class MessageRepository {
  Future<List<Message>> loadMessages({
    required String userId,
    int limit,
    String? cursorIso,
  });

  Future<Message> sendMessage(Message message);

  void subscribeToMessages({
    required String userId,
    required void Function(Message message) onNewMessage,
  });
}
