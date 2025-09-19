import 'package:dailymoji/domain/entities/chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatRepository {
  Future<List<Chat>> loadMessages({
    required String userId,
    int limit,
    String? cursorIso,
  });

  Future<void> sendMessage(Chat chat);

  void subscribeToMessages({
    required String userId,
    required void Function(Chat chat) onNewMessage,
  });
}
