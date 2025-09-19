import 'package:dailymoji/domain/entities/chat.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';

class LoadMessagesUseCase {
  final ChatRepository repository;

  LoadMessagesUseCase(this.repository);

  Future<List<Chat>> execute({
    required String userId,
    int limit = 50,
    String? cursorIso,
  }) {
    return repository.loadMessages(
      userId: userId,
      limit: limit,
      cursorIso: cursorIso,
    );
  }
}
