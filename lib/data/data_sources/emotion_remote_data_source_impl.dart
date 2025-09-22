// data/data_sources/emotion_remote_data_source_impl.dart

import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart'; // URL 가져오기
import 'package:dailymoji/data/data_sources/emotion_remote_data_source.dart';
import 'package:dailymoji/data/dtos/emotional_record_dto.dart';
import 'package:http/http.dart' as http; // http 패키지 추가

class EmotionRemoteDataSourceImpl implements EmotionRemoteDataSource {
  // SupabaseClient 의존성 제거, 생성자 비우기
  EmotionRemoteDataSourceImpl();

  @override
  Future<EmotionalRecordDto> analyzeEmotion({
    required String userId,
    required String text,
    String? emotion,
    Map<String, dynamic>? onboarding,
  }) async {
    try {
      // 1. .env 파일에 설정한 FastAPI 서버 URL로 /checkin 엔드포인트 호출
      final url = "${getBaseUrl()}/checkin";
      print("Calling API: $url"); // 디버깅용 로그

      // 2. 원래 코드처럼 http.post를 사용하여 API 호출
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'user_id': userId,
          'text': text,
          'icon': emotion, // 'emotion' 파라미터를 백엔드 모델에 맞게 'icon'으로 매핑
          'timestamp': DateTime.now().toIso8601String(),
          'onboarding': onboarding,
          // 필요하다면 다른 파라미터도 추가할 수 있습니다.
        }),
      );

      // --- API 디버깅!! ---
      final responseBody = utf8.decode(response.bodyBytes);
      print("--- 백엔드로부터 받은 실제 응답 ---");
      print(responseBody);
      // ---------------------------------------------

      // 3. API 응답 처리
      if (response.statusCode == 200) {
        // 한글 깨짐 방지를 위해 UTF-8로 디코딩
        final responseBody = utf8.decode(response.bodyBytes);
        final json = jsonDecode(responseBody);
        return EmotionalRecordDto.fromJson(json);
      } else {
        // 에러 발생 시
        throw Exception(
            'Failed to analyze emotion: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print("Emotion analysis http error: $e");
      rethrow;
    }
  }
}
