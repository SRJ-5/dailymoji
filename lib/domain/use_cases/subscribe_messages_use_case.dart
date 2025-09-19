import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/repositories/message_repository.dart';

class SubscribeMessagesUseCase {
  final MessageRepository repository;

  SubscribeMessagesUseCase(this.repository);

  void execute({
    required String userId,
    required void Function(Message message) onNewMessage,
  }) {
    repository.subscribeToMessages(
      userId: userId,
      onNewMessage: onNewMessage,
    );
  }
}
