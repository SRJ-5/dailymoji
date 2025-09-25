import 'package:dailymoji/domain/repositories/message_repository.dart';

class UpdateMessageSessionIdUseCase {
  final MessageRepository repository;

  UpdateMessageSessionIdUseCase(this.repository);

  // 이 UseCase는 messageId와 sessionId 두 개의 파라미터를 받아서
  // Repository에 전달하는 역할만 수행합니다.
  Future<void> execute({required String messageId, required String sessionId}) {
    return repository.updateMessageSessionId(
      messageId: messageId,
      sessionId: sessionId,
    );
  }
}
