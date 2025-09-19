import 'package:dailymoji/data/dtos/message_dto.dart';

abstract class MessageRemoteDataSource {
  Future<List<MessageDto>> fetchMessages({
    required String userId,
    int limit,
    String? cursorIso,
  });

  Future<void> insertMessage(MessageDto messageDto);

  void subscribeToMessages({
    required String userId,
    required void Function(MessageDto message) onNewMessage,
  });
}
