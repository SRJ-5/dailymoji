import 'package:dailymoji/domain/entities/assessment_questions.dart';

abstract class AssessmentRepository {
  Future<AssessmentQuestions?> getQuestion(String cluster);
}
