// data/repositories/emoji_reaction_repository.dart
// 채팅 이모지 전용! /analyze(text="")로 세션 생성 + 대사 수신

import 'package:dailymoji/domain/entities/emotional_record.dart';
import 'package:dailymoji/domain/use_cases/user_use_cases/analyze_emotion_use_case.dart';

abstract class EmojiReactionRepository {
  Future<EmotionalRecord> getReactionWithSession({
    // RIN ♥ : 반환 타입을 EmotionalRecord로 변경
    required String userId,
    required String emotion,
    Map<String, dynamic>? onboarding,
    String? characterPersonality,
  });
}

class EmojiReactionRepositoryImpl implements EmojiReactionRepository {
  final AnalyzeEmotionUseCase _analyze;

  EmojiReactionRepositoryImpl(this._analyze);

  @override
  Future<EmotionalRecord> getReactionWithSession({
    // RIN ♥ : 반환 타입을 EmotionalRecord로 변경
    required String userId,
    required String emotion,
    Map<String, dynamic>? onboarding,
    String? characterPersonality,
  }) async {
    final r = await _analyze.execute(
      userId: userId,
      text: "", // [KEY] EMOJI_ONLY Quick Save
      emotion: emotion,
      onboarding: onboarding ?? const {},
    );

    // RIN ♥ : EmotionalRecord 객체 자체를 반환
    return r;
  }
}
