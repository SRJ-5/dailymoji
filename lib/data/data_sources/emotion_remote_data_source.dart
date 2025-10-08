// 감정 분석 API 호출을 위한 DataSource 인터페이스
import 'package:dailymoji/data/dtos/emotional_record_dto.dart';
import 'package:dailymoji/domain/entities/message.dart';

abstract class EmotionRemoteDataSource {
  Future<EmotionalRecordDto> analyzeEmotion({
    required String userId,
    required String text,
    String? emotion,
    Map<String, dynamic>? onboarding,
    String? characterPersonality,
    List<Message>? history, // 이전 대화 기록을 위한 파라미터 추가
    Map<String, dynamic>? adhdContext,
  });
}
