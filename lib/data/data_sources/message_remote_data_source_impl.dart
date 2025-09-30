import 'dart:async';

import 'package:dailymoji/data/data_sources/message_remote_data_source.dart';
import 'package:dailymoji/data/dtos/message_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final SupabaseClient client;

  MessageRemoteDataSourceImpl(this.client);

  @override
  Future<List<MessageDto>> fetchMessages({
    required String userId,
    int limit = 50,
    String? cursorIso, // created_at 커서(ISO8601 문자열)
  }) async {
    var query = client.from("messages").select().eq("user_id", userId);

    if (cursorIso != null) {
      query = query.lt("created_at", cursorIso);
    }

    // 최신 메시지 50개를 가져오기 위해 먼저 최신 순으로 정렬해서 limit 적용
    final result =
        await query.order("created_at", ascending: false).limit(limit);

    final rows = (result as List).cast<Map<String, dynamic>>();
    final messages = rows.map((m) => MessageDto.fromJson(m)).toList();

    // 오래된 순으로 다시 정렬해서 반환(지금은 chatViewModel에서 오래된 순으로 받는걸로 알고있음)
    messages.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));

    return messages;
  }

  @override
  Future<MessageDto> insertMessage(MessageDto messageDto) async {
    final response = await client
        .from("messages")
        .insert(messageDto.toJson())
        .select()
        .single();

    return MessageDto.fromJson(response);
  }

  @override
  void subscribeToMessages({
    required String userId,
    required void Function(MessageDto messageDto) onNewMessage,
  }) {
    client
        .channel("message_changes_$userId")
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: "public",
          table: "messages",
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: "user_id",
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            onNewMessage(MessageDto.fromJson(record));
          },
        )
        .subscribe();
  }

  @override
  Future<void> updateMessageSessionId({
    required String messageId,
    required String sessionId,
  }) async {
    await client
        .from("messages")
        .update({'session_id': sessionId}).eq('id', messageId);
  }
}
