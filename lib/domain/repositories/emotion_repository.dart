// 감정 분석 Repository 인터페이스
import 'package:dailymoji/domain/entities/emotional_record.dart';

abstract class EmotionRepository {
  Future<EmotionalRecord> analyzeEmotion({
    required String userId,
    required String text,
    String? emotion,
    Map<String, dynamic>? onboarding,
  });
}
