import 'package:dailymoji/domain/entities/assessment_responses.dart';

abstract class AssessmentResponseRepository {
  Future<void> submitAssessment(
      AssessmentResponses assessmentResponses);
}
