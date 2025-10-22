import 'package:dailymoji/data/data_sources/assessment_history_data_source.dart';
import 'package:dailymoji/data/dtos/assessment_history_dto.dart';
import 'package:dailymoji/domain/entities/assessment_last_survey.dart';
import 'package:dailymoji/domain/repositories/assessment_history_repository.dart';

class AssessmentHistoryRepositoryImpl implements AssessmentHistoryRepository {
  final AssessmentHistoryDataSource dataSource;
  AssessmentHistoryRepositoryImpl(this.dataSource);

  @override
  Future<AssessmentLastSurvey?> fetchLastSurvey(String userId) async {
    final dto = await dataSource.fetchLastSurvey(userId);
    if (dto == null) return null;
    return _toEntity(dto);
  }

  AssessmentLastSurvey _toEntity(AssessmentHistoryDto dto) {
    return AssessmentLastSurvey(
      userId: dto.userId,
      createdAt: dto.createdAt,
    );
  }
}
