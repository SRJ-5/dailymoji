// lib/domain/repositories/assessment_history_repository.dart
import 'package:dailymoji/domain/entities/assessment_last_survey.dart';

abstract class AssessmentHistoryRepository {
  Future<AssessmentLastSurvey?> fetchLastSurvey(String userId);
}
