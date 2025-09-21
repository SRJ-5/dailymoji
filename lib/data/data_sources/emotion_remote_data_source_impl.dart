// Supabase Edge Function을 호출하는 DataSource 구현체
import 'package:dailymoji/data/data_sources/emotion_remote_data_source.dart';
import 'package:dailymoji/data/dtos/emotional_record_dto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmotionRemoteDataSourceImpl implements EmotionRemoteDataSource {
  final SupabaseClient client;

  EmotionRemoteDataSourceImpl(this.client);

  @override
  Future<EmotionalRecordDto> analyzeEmotion({
    required String userId,
    required String text,
    String? emotion,
  }) async {
    try {
      final response = await client.functions.invoke(
        'checkin', // Supabase Edge Function 이름
        body: {
          'userId': userId,
          'text': text,
          'selectedEmotion': emotion,
        },
      );

      if (response.status == 200) {
        return EmotionalRecordDto.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to analyze emotion: ${response.status} ${response.data}');
      }
    } on FunctionException catch (e) {
      // Supabase 함수 호출 관련 에러 처리
      print("Supabase function error: $e");
      rethrow;
    } catch (e) {
      // 일반 에러 처리
      print("Emotion analysis error: $e");
      rethrow;
    }
  }
}
