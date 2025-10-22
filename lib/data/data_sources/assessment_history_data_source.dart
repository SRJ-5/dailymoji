import 'package:dailymoji/data/dtos/assessment_history_dto.dart';

abstract class AssessmentHistoryDataSource {
  Future<AssessmentHistoryDto?> fetchLastSurvey(String userId);
}
