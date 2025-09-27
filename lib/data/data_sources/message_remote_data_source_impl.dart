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
    // 오늘 00:00 ~ 내일 00:00 (로컬 기준) → UTC ISO
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final startIso = startOfDay.toUtc().toIso8601String();
    final endIso = endOfDay.toUtc().toIso8601String();

    var base = client
        .from("messages")
        .select()
        .eq("user_id", userId)
        .gte("created_at", startIso)
        .lt("created_at", endIso);

    if (cursorIso != null) {
      base = base.gt("created_at", cursorIso);
    }

    // 3) 그 다음에 정렬/리밋
    // RIN: 'ascending: true'였던... 바보.. 'ascending: false'로 변경하여 최신 메시지부터 가져오도록 수정함
    final result =
        await base.order("created_at", ascending: false).limit(limit);

    final rows = (result as List).cast<Map<String, dynamic>>();
    return rows.map((m) => MessageDto.fromJson(m)).toList();
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
