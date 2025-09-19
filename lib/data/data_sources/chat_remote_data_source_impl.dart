import 'dart:async';

import 'package:dailymoji/data/data_sources/chat_remote_data_source.dart';
import 'package:dailymoji/data/dtos/chat_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final supabase = Supabase.instance.client;

  @override
  Future<List<ChatDto>> fetchChats(String userId) async {
    final response = await supabase.from("chat").select().eq("user_id", userId).order("created_at", ascending: true);

    return (response as List).map((json) => ChatDto.fromJson(json)).toList();
  }

  @override
  Future<bool> insertChat(ChatDto dto) async {
    try {
      await supabase.from("chat").insert(dto.toJson());
      return true;
    } catch (e) {
      print("insertChat error: $e");
      return false;
    }
  }

  @override
  Stream<ChatDto> subscribeToChats(String userId) {
    final controller = StreamController<ChatDto>();

    final channel = supabase.channel("chat_stream_$userId");

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: "public",
      table: "chat",
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: "user_id",
        value: userId,
      ),
      callback: (payload) {
        final chatDto = ChatDto.fromJson(payload.newRecord);
        controller.add(chatDto);
      },
    );

    channel.subscribe();

    return controller.stream;
  }
}
