// DataSource Provider
import 'package:dailymoji/data/data_sources/chat_remote_data_source.dart';
import 'package:dailymoji/data/data_sources/chat_remote_data_source_impl.dart';
import 'package:dailymoji/data/repositories/chat_repository_impl.dart';
import 'package:dailymoji/domain/repositories/chat_repository.dart';
import 'package:dailymoji/domain/use_cases/load_messages_use_case.dart';
import 'package:dailymoji/domain/use_cases/send_message_use_case.dart';
import 'package:dailymoji/domain/use_cases/subscribe_messages_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>(
  (ref) {
    final client = ref.read(supabaseClientProvider);
    return ChatRemoteDataSourceImpl(client);
  },
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) {
    final dataSource = ref.watch(chatRemoteDataSourceProvider);
    return ChatRepositoryImpl(dataSource);
  },
);

final loadMessagesUseCaseProvider = Provider<LoadMessagesUseCase>(
  (ref) {
    final repo = ref.watch(chatRepositoryProvider);
    return LoadMessagesUseCase(repo);
  },
);

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
  (ref) {
    final repo = ref.watch(chatRepositoryProvider);
    return SendMessageUseCase(repo);
  },
);

final subscribeMessagesUseCaseProvider = Provider<SubscribeMessagesUseCase>(
  (ref) {
    final repo = ref.watch(chatRepositoryProvider);
    return SubscribeMessagesUseCase(repo);
  },
);
