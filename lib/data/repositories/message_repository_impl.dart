import 'package:dailymoji/data/data_sources/message_remote_data_source.dart';
import 'package:dailymoji/data/dtos/message_dto.dart';
import 'package:dailymoji/domain/entities/message.dart';
import 'package:dailymoji/domain/repositories/message_repository.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Message>> loadMessages({
    required String userId,
    int limit = 50,
    String? cursorIso,
  }) async {
    final dtos = await remoteDataSource.fetchMessages(
      userId: userId,
      limit: limit,
      cursorIso: cursorIso,
    );
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<void> sendMessage(Message message) async {
    final dto = MessageDto.fromEntity(message);
    await remoteDataSource.insertMessage(dto);
  }

  @override
  void subscribeToMessages({
    required String userId,
    required void Function(Message message) onNewMessage,
  }) {
    remoteDataSource.subscribeToMessages(
      userId: userId,
      onNewMessage: (dto) => onNewMessage(dto.toEntity()),
    );
  }
}
