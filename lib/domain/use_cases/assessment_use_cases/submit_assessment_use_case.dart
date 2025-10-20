import 'package:dailymoji/domain/entities/assessment_responses.dart';
import 'package:dailymoji/domain/repositories/assessment_response_repository.dart';

class SubmitAssessmentUseCase {
  SubmitAssessmentUseCase(this._responseRepository);
  final AssessmentResponseRepository _responseRepository;

  Future<void> excute(
      AssessmentResponses assessmentResponses) async {
    await _responseRepository
        .submitAssessment(assessmentResponses);
  }
}
