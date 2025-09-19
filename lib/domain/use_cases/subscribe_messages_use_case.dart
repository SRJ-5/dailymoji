import 'package:dailymoji/domain/entities/chat.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';

class SubscribeMessagesUseCase {
  final ChatRepository repository;

  SubscribeMessagesUseCase(this.repository);

  Stream<Chat> execute(String userId) {
    return repository.subscribeMessages(userId);
  }
}
