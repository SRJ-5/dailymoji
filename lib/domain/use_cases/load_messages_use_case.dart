import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/repositories/message_repository.dart';

class LoadMessagesUseCase {
  final MessageRepository repository;

  LoadMessagesUseCase(this.repository);

  Future<List<Message>> execute({
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
