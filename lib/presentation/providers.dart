// // DataSource Provider
// import 'package:dailymoji/data/data_sources/message_remote_data_source.dart';
// import 'package:dailymoji/data/data_sources/message_remote_data_source_impl.dart';
// import 'package:dailymoji/data/repositories/message_repository_impl.dart';
// import 'package:dailymoji/domain/repositories/message_repository.dart';
// import 'package:dailymoji/domain/use_cases/load_messages_use_case.dart';
// import 'package:dailymoji/domain/use_cases/send_message_use_case.dart';
// import 'package:dailymoji/domain/use_cases/subscribe_messages_use_case.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// final supabaseClientProvider = Provider<SupabaseClient>((ref) {
//   return Supabase.instance.client;
// });

// final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>(
//   (ref) {
//     final client = ref.read(supabaseClientProvider);
//     return MessageRemoteDataSourceImpl(client);
//   },
// );

// final messageRepositoryProvider = Provider<MessageRepository>(
//   (ref) {
//     final dataSource = ref.watch(messageRemoteDataSourceProvider);
//     return MessageRepositoryImpl(dataSource);
//   },
// );

// final loadMessagesUseCaseProvider = Provider<LoadMessagesUseCase>(
//   (ref) {
//     final repo = ref.watch(messageRepositoryProvider);
//     return LoadMessagesUseCase(repo);
//   },
// );

// final sendMessageUseCaseProvider = Provider<SendMessageUseCase>(
//   (ref) {
//     final repo = ref.watch(messageRepositoryProvider);
//     return SendMessageUseCase(repo);
//   },
// );

// final subscribeMessagesUseCaseProvider = Provider<SubscribeMessagesUseCase>(
//   (ref) {
//     final repo = ref.watch(messageRepositoryProvider);
//     return SubscribeMessagesUseCase(repo);
//   },
// );
