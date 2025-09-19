import 'package:dailymoji/data/data_sources/chat_remote_data_source.dart';
import 'package:dailymoji/data/dtos/chat_dto.dart';
import 'package:dailymoji/domain/entities/chat.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Chat>> loadMessages(String userId) async {
    final dtos = await remoteDataSource.fetchChats(userId);
    return dtos.map((dto) => dto.toEntity()).toList();
  }

  @override
  Future<bool> sendMessage(Chat chat) async {
    final dto = ChatDto.fromEntity(chat);
    return await remoteDataSource.insertChat(dto);
  }

  @override
  Stream<Chat> subscribeMessages(String userId) {
    return remoteDataSource.subscribeToChats(userId).map((dto) => dto.toEntity());
  }
}
