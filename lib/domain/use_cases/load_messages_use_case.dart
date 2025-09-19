import 'package:dailymoji/domain/entities/chat.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';

class LoadMessagesUseCase {
  final ChatRepository repository;

  LoadMessagesUseCase(this.repository);

  Future<List<Chat>> execute(String userId) {
    return repository.loadMessages(userId);
  }
}
