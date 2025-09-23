import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/data/data_sources/emotion_remote_data_source.dart';
import 'package:dailymoji/data/data_sources/emotion_remote_data_source_impl.dart';
import 'package:dailymoji/data/data_sources/message_remote_data_source.dart';
import 'package:dailymoji/data/data_sources/message_remote_data_source_impl.dart';
import 'package:dailymoji/data/repositories/emotion_repository_impl.dart';
import 'package:dailymoji/data/repositories/message_repository_impl.dart';
import 'package:dailymoji/data/repositories/solution_repository_impl.dart';
import 'package:dailymoji/domain/entities/solution.dart';
import 'package:dailymoji/domain/repositories/emotion_repository.dart';
import 'package:dailymoji/domain/repositories/message_repository.dart';
import 'package:dailymoji/domain/repositories/solution_repository.dart';
import 'package:dailymoji/domain/use_cases/analyze_emotion_use_case.dart';
import 'package:dailymoji/domain/use_cases/load_messages_use_case.dart';
import 'package:dailymoji/domain/use_cases/send_message_use_case.dart';
import 'package:dailymoji/domain/use_cases/subscribe_messages_use_case.dart';
import 'package:dailymoji/domain/use_cases/update_message_session_id_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// -----------------------------------------------------------------------------
// Core & External Services
// -----------------------------------------------------------------------------

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final httpClientProvider = Provider((ref) => http.Client());

// -----------------------------------------------------------------------------
// Data Sources
// -----------------------------------------------------------------------------

final messageRemoteDataSourceProvider =
    Provider<MessageRemoteDataSource>((ref) {
  return MessageRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final emotionRemoteDataSourceProvider =
    Provider<EmotionRemoteDataSource>((ref) {
  return EmotionRemoteDataSourceImpl();
});

// -----------------------------------------------------------------------------
// Repositories
// -----------------------------------------------------------------------------

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepositoryImpl(ref.watch(messageRemoteDataSourceProvider));
});

final emotionRepositoryProvider = Provider<EmotionRepository>((ref) {
  return EmotionRepositoryImpl(ref.watch(emotionRemoteDataSourceProvider));
});

final solutionRepositoryProvider = Provider<SolutionRepository>((ref) {
  final client = ref.watch(httpClientProvider);
  return SolutionRepositoryImpl(client);
});

// -----------------------------------------------------------------------------
// Use Cases
// -----------------------------------------------------------------------------

final loadMessagesUseCaseProvider = Provider<LoadMessagesUseCase>((ref) {
  return LoadMessagesUseCase(ref.watch(messageRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(messageRepositoryProvider));
});

final subscribeMessagesUseCaseProvider =
    Provider<SubscribeMessagesUseCase>((ref) {
  return SubscribeMessagesUseCase(ref.watch(messageRepositoryProvider));
});

final analyzeEmotionUseCaseProvider = Provider<AnalyzeEmotionUseCase>((ref) {
  return AnalyzeEmotionUseCase(ref.watch(emotionRepositoryProvider));
});

final updateMessageSessionIdUseCaseProvider =
    Provider<UpdateMessageSessionIdUseCase>((ref) {
  return UpdateMessageSessionIdUseCase(ref.watch(messageRepositoryProvider));
});

// -----------------------------------------------------------------------------
// Feature-Specific Providers
// -----------------------------------------------------------------------------

// solutionId를 받아 특정 솔루션 정보를 비동기적으로 가져오는 FutureProvider
final solutionProvider =
    FutureProvider.autoDispose.family<Solution, String>((ref, solutionId) {
  final repository = ref.watch(solutionRepositoryProvider);
  return repository.fetchSolutionById(solutionId);
});
