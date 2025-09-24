import 'package:dailymoji/data/data_sources/emotion_remote_data_source.dart';
import 'package:dailymoji/data/data_sources/emotion_remote_data_source_impl.dart';
import 'package:dailymoji/data/data_sources/message_remote_data_source.dart';
import 'package:dailymoji/data/data_sources/message_remote_data_source_impl.dart';
import 'package:dailymoji/data/data_sources/solution_remote_data_source_impl.dart';
import 'package:dailymoji/data/repositories/emotion_repository_impl.dart';
import 'package:dailymoji/data/repositories/message_repository_impl.dart';
import 'package:dailymoji/data/repositories/reaction_repository.dart';
import 'package:dailymoji/data/repositories/solution_repository_impl.dart';
import 'package:dailymoji/domain/entities/solution.dart';
import 'package:dailymoji/domain/repositories/emotion_repository.dart';
import 'package:dailymoji/domain/repositories/message_repository.dart';
import 'package:dailymoji/domain/repositories/solution_repository.dart';
import 'package:dailymoji/domain/use_cases/analyze_emotion_use_case.dart';
import 'package:dailymoji/domain/use_cases/get_reaction_script_use_case.dart';
import 'package:dailymoji/domain/use_cases/load_messages_use_case.dart';
import 'package:dailymoji/domain/use_cases/propose_solution_usecase.dart';
import 'package:dailymoji/domain/use_cases/send_message_use_case.dart';
import 'package:dailymoji/domain/use_cases/subscribe_messages_use_case.dart';
import 'package:dailymoji/domain/use_cases/update_message_session_id_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

final solutionRemoteDataSourceProvider =
    Provider<SolutionRemoteDataSourceImpl>((ref) {
  final client = ref.watch(httpClientProvider);
  return SolutionRemoteDataSourceImpl(client);
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
  return SolutionRepositoryImpl(ref.watch(solutionRemoteDataSourceProvider));
});

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return ReactionRepositoryImpl();
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

// 솔루션 제안
final proposeSolutionUseCaseProvider = Provider<ProposeSolutionUseCase>((ref) {
  return ProposeSolutionUseCase(ref.watch(solutionRepositoryProvider));
});

final getReactionScriptUseCaseProvider =
    Provider<GetReactionScriptUseCase>((ref) {
  final repository = ref.watch(reactionRepositoryProvider);
  return GetReactionScriptUseCase(repository);
});

// -----------------------------------------------------------------------------
// Feature-Specific Providers
// -----------------------------------------------------------------------------

// solutionId를 받아 특정 솔루션 정보 가져옴
final solutionProvider =
    FutureProvider.autoDispose.family<Solution, String>((ref, solutionId) {
  final repository = ref.watch(solutionRepositoryProvider);
  return repository.fetchSolutionById(solutionId);
});

// 선택한 이모지
final selectedEmotionProvider = StateProvider<String?>((ref) => null);
// 홈에서 말시키는 대사 (그때그때 랜덤하게 하나만 받아오기)
final homeDialogueProvider = FutureProvider<String>((ref) async {
  final selectedEmotion = ref.watch(selectedEmotionProvider);
  return ref.watch(getReactionScriptUseCaseProvider).execute(selectedEmotion);
});
