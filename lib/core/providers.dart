// lib/core/providers.dart

// 필요한 import만 남기고, 없는 파일에 대한 import는 주석 처리합니다.
// import 'package:dailymoji/data/data_sources/emotion_remote_data_source.dart';
// import 'package:dailymoji/data/data_sources/emotion_remote_data_source_impl.dart';
// import 'package:dailymoji/data/data_sources/message_remote_data_source.dart';
// import 'package:dailymoji/data/data_sources/message_remote_data_source_impl.dart';
import 'package:dailymoji/data/data_sources/report_remote_data_source.dart';
// import 'package:dailymoji/data/repositories/emotion_repository_impl.dart';
// import 'package:dailymoji/data/repositories/message_repository_impl.dart';
import 'package:dailymoji/data/repositories/report_repository_impl.dart';
// import 'package:dailymoji/domain/repositories/emotion_repository.dart';
// import 'package:dailymoji/domain/repositories/message_repository.dart';
import 'package:dailymoji/domain/repositories/report_repository.dart';
// import 'package:dailymoji/domain/use_cases/analyze_emotion_use_case.dart';
// import 'package:dailymoji/domain/use_cases/load_messages_use_case.dart';
// import 'package:dailymoji/domain/use_cases/send_message_use_case.dart';
// import 'package:dailymoji/domain/use_cases/subscribe_messages_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// #################################################################
// ## Core Providers
// #################################################################
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// #################################################################
// ## Data Source Providers
// #################################################################

// final messageRemoteDataSourceProvider = Provider<MessageRemoteDataSource>((ref) {
//   return MessageRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
// });

// final emotionRemoteDataSourceProvider = Provider<EmotionRemoteDataSource>((ref) {
//   return EmotionRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
// });

final reportRemoteDataSourceProvider = Provider<ReportRemoteDataSource>((ref) {
  return ReportRemoteDataSource(ref.watch(supabaseClientProvider));
});

// #################################################################
// ## Repository Providers
// #################################################################

// final messageRepositoryProvider = Provider<MessageRepository>((ref) {
//   return MessageRepositoryImpl(ref.watch(messageRemoteDataSourceProvider));
// });

// final emotionRepositoryProvider = Provider<EmotionRepository>((ref) {
//   return EmotionRepositoryImpl(ref.watch(emotionRemoteDataSourceProvider));
// });

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(reportRemoteDataSourceProvider));
});


// #################################################################
// ## Use Case Providers
// #################################################################

// final loadMessagesUseCaseProvider = Provider<LoadMessagesUseCase>((ref) {
//   return LoadMessagesUseCase(ref.watch(messageRepositoryProvider));
// });

// final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
//   return SendMessageUseCase(ref.watch(messageRepositoryProvider));
// });

// final subscribeMessagesUseCaseProvider = Provider<SubscribeMessagesUseCase>((ref) {
//   return SubscribeMessagesUseCase(ref.watch(messageRepositoryProvider));
// });

// final analyzeEmotionUseCaseProvider = Provider<AnalyzeEmotionUseCase>((ref) {
//   return AnalyzeEmotionUseCase(ref.watch(emotionRepositoryProvider));
// });