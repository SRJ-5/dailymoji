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

//감정 분석 흐름의 연장선으로, 피드백 결과로 weight를 부여하기 위함
  Future<void> submitSolutionFeedback({
    required String userId,
    required String solutionId,
    String? sessionId,
    required String solutionType,
    required String feedback,
  });
}
