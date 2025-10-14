import 'package:dailymoji/domain/entities/assessment_questions.dart';
import 'package:dailymoji/domain/repositories/assessment_repository.dart';

class GetquestionUseCase {
  GetquestionUseCase(this._assessmentRepository);
  final AssessmentRepository _assessmentRepository;

  Future<AssessmentQuestions?> excute(String cluster) async {
    final result =
        await _assessmentRepository.getQuestion(cluster);
    return result;
  }
}
