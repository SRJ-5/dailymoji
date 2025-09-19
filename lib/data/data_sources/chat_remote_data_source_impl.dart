import 'dart:async';

import 'package:dailymoji/data/data_sources/chat_remote_data_source.dart';
import 'package:dailymoji/data/dtos/chat_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient client;

  ChatRemoteDataSourceImpl(this.client);

  @override
  Future<List<ChatDto>> fetchMessages({
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

    var base = client.from("chat").select().eq("user_id", userId).gte("created_at", startIso).lt("created_at", endIso);

    if (cursorIso != null) {
      base = base.gt("created_at", cursorIso);
    }

    // 3) 그 다음에 정렬/리밋
    final result = await base.order("created_at", ascending: true).limit(limit);

    final rows = (result as List).cast<Map<String, dynamic>>();
    return rows.map((m) => ChatDto.fromJson(m)).toList();
  }

  @override
  Future<void> insertMessage(ChatDto chat) async {
    await client.from("chat").insert(chat.toJson());
  }

  @override
  void subscribeToMessages({
    required String userId,
    required void Function(ChatDto message) onNewMessage,
  }) {
    client
        .channel("chat_changes_$userId")
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: "public",
          table: "chat",
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: "user_id",
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            onNewMessage(ChatDto.fromJson(record));
          },
        )
        .subscribe();
  }
}
