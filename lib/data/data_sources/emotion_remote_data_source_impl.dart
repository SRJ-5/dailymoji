// data/data_sources/emotion_remote_data_source_impl.dart

import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart'; // URL 가져오기
import 'package:dailymoji/data/data_sources/emotion_remote_data_source.dart';
import 'package:dailymoji/data/dtos/emotional_record_dto.dart';
import 'package:dailymoji/domain/enums/enum_data.dart';
import 'package:http/http.dart' as http; // http 패키지 추가

class EmotionRemoteDataSourceImpl implements EmotionRemoteDataSource {
  @override
  Future<EmotionalRecordDto> analyzeEmotion({
    required String userId,
    required String text,
    String? emotion, // 홈 또는 채팅에서 선택한 이모지
    Map<String, dynamic>? onboarding,
    String? characterPersonality,
  }) async {
    try {
      // 1. .env 파일에 설정한 FastAPI 서버 URL로 /analyze 엔드포인트 호출
      final url = "${ApiConfig.baseUrl}/analyze";
      print("Calling API: $url with text: '$text', icon: '$emotion'");

// 🤩 RIN: 백엔드로 보낼 때 DB에 저장된 dbValue('prob_solver' 등) 보내기
      final personalityDbValue = characterPersonality != null
          ? CharacterPersonality.values
              .firstWhere(
                (e) => e.label == characterPersonality,
                orElse: () => CharacterPersonality.probSolver, // 기본값
              )
              .dbValue
          : null;

      // 2. 원래 코드처럼 http.post를 사용하여 API 호출
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'user_id': userId,
          'text': text,
          'icon': emotion, // 백엔드의 payload.icon과 매칭
          'timestamp': DateTime.now().toIso8601String(),
          'onboarding': onboarding,
          'character_personality': personalityDbValue,
        }),
      );

      // --- API 디버깅!! ---
      final responseBody = utf8.decode(response.bodyBytes);
      print("--- 백엔드로부터 받은 실제 응답 ---");
      print(responseBody);
      // ---------------------------------------------

      // 3. API 응답 처리
      if (response.statusCode == 200) {
        final jsonResult = jsonDecode(responseBody);

        if (jsonResult == null || jsonResult is! Map<String, dynamic>) {
          throw Exception(
              'Received null or invalid JSON from API. Response Body: $responseBody');
        }

        return EmotionalRecordDto.fromJson(jsonResult);
      } else {
        throw Exception(
            'Failed to analyze emotion: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print("Emotion analysis http error: $e");
      rethrow;
    }
  }
}
