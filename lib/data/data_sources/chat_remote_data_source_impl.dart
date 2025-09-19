import 'package:dailymoji/data/data_sources/chat_remote_data_source.dart';
import 'package:dailymoji/data/dtos/chat_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final supabase = Supabase.instance.client;

  @override
  Future<List<ChatDto>> fetchChats(String userId) async {
    final response = await supabase.from('chat').select().eq('user_id', userId).order('created_at', ascending: true);

    return (response as List).map((json) => ChatDto.fromJson(json)).toList();
  }

  @override
  Future<bool> insertChat(ChatDto dto) async {
    try {
      await supabase.from('chat').insert(dto.toJson());
      return true;
    } catch (e) {
      print('insertChat error: $e');
      return false;
    }
  }
}
