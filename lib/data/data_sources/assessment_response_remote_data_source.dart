import 'package:dailymoji/data/dtos/assessment_responses_dto.dart';

abstract class AssessmentResponseRemoteDataSource {
  Future<void> submitAssessment(
      AssessmentResponsesDto assessmentResponses);
}
