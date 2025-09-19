import 'package:dailymoji/data/data_sources/chat_remote_data_source.dart';
import 'package:dailymoji/data/dtos/chat_dto.dart';
import 'package:dailymoji/domain/entities/chat.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Chat>> loadMessages({
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
  Future<void> sendMessage(Chat message) async {
    final dto = ChatDto.fromEntity(message);
    await remoteDataSource.insertMessage(dto);
  }

  @override
  void subscribeToMessages({
    required String userId,
    required void Function(Chat message) onNewMessage,
  }) {
    remoteDataSource.subscribeToMessages(
      userId: userId,
      onNewMessage: (dto) => onNewMessage(dto.toEntity()),
    );
  }
}
