import 'package:dailymoji/domain/entities/chat.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';

class SubscribeMessagesUseCase {
  final ChatRepository repository;

  SubscribeMessagesUseCase(this.repository);

  void execute({
    required String userId,
    required void Function(Chat message) onNewMessage,
  }) {
    repository.subscribeToMessages(
      userId: userId,
      onNewMessage: onNewMessage,
    );
  }
}
