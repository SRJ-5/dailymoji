import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/repositories/message_repository.dart';

class SendMessageUseCase {
  final MessageRepository repository;

  SendMessageUseCase(this.repository);

  Future<void> execute(Message message) {
    return repository.sendMessage(message);
  }
}
