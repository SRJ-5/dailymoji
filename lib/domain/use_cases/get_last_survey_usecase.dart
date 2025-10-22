import 'package:dailymoji/domain/entities/assessment_last_survey.dart';
import 'package:dailymoji/domain/repositories/assessment_history_repository.dart';

class GetLastSurveyUsecase {
  final AssessmentHistoryRepository repo;
  GetLastSurveyUsecase(this.repo);

  Future<AssessmentLastSurvey?> execute(String userId) {
    return repo.fetchLastSurvey(userId);
  }
}
