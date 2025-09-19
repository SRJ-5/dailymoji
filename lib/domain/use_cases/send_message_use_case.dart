import 'package:dailymoji/domain/entities/chat.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<bool> execute(Chat chat) {
    return repository.sendMessage(chat);
  }
}
