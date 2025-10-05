// 감정 분석 비즈니스 로직을 담당하는 UseCase
import 'package:dailymoji/domain/entities/emotional_record.dart';
import 'package:dailymoji/domain/repositories/emotion_repository.dart';

class AnalyzeEmotionUseCase {
  final EmotionRepository repository;

  AnalyzeEmotionUseCase(this.repository);

  Future<EmotionalRecord> execute({
    required String userId,
    required String text,
    String? emotion,
    Map<String, dynamic>? onboarding,
    String? characterPersonality,
  }) {
    return repository.analyzeEmotion(
      userId: userId,
      text: text,
      emotion: emotion,
      onboarding: onboarding,
      characterPersonality: characterPersonality,
    );
  }
}
