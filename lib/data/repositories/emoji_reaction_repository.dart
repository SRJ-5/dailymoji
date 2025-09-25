// data/repositories/emoji_reaction_repository.dart
// 채팅 이모지 전용! /analyze(text="")로 세션 생성 + 대사 수신

import 'package:dailymoji/domain/use_cases/analyze_emotion_use_case.dart';

abstract class EmojiReactionRepository {
  Future<
      ({
        String text,
        String? sessionId,
        Map<String, dynamic> intervention,
      })> getReactionWithSession({
    required String userId,
    required String emotion,
    Map<String, dynamic>? onboarding,
  });
}

class EmojiReactionRepositoryImpl implements EmojiReactionRepository {
  final AnalyzeEmotionUseCase _analyze; // [ADDED] UseCase 주입

  EmojiReactionRepositoryImpl(this._analyze);

  @override
  Future<
      ({
        String text,
        String? sessionId,
        Map<String, dynamic> intervention,
      })> getReactionWithSession({
    required String userId,
    required String emotion,
    Map<String, dynamic>? onboarding,
  }) async {
    final r = await _analyze.execute(
      userId: userId,
      text: "", // [KEY] EMOJI_ONLY Quick Save
      emotion: emotion,
      onboarding: onboarding ?? const {},
    );

    return (
      text: (r.intervention?['text'] as String?) ?? "어떤 일 때문에 그렇게 느끼셨나요?",
      sessionId: r.sessionId,
      intervention: Map<String, dynamic>.from(r.intervention ?? const {}),
    );
  }
}
