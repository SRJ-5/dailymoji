// 감정 분석 Repository 구현체
import 'package:dailymoji/data/data_sources/emotion_remote_data_source.dart';
import 'package:dailymoji/domain/entities/emotional_record.dart';
import 'package:dailymoji/domain/repositories/emotion_repository.dart';

class EmotionRepositoryImpl implements EmotionRepository {
  final EmotionRemoteDataSource remoteDataSource;

  EmotionRepositoryImpl(this.remoteDataSource);

  @override
  Future<EmotionalRecord> analyzeEmotion({
    required String userId,
    required String text,
    String? emotion,
  }) async {
    final dto = await remoteDataSource.analyzeEmotion(
      userId: userId,
      text: text,
      emotion: emotion,
    );
    return dto.toEntity();
  }
}
