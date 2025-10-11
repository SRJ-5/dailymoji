import 'package:dailymoji/data/data_sources/srj5_questions_data_source.dart';
import 'package:dailymoji/domain/entities/assessment_questions.dart';
import 'package:dailymoji/domain/repositories/assessment_repository.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  AssessmentRepositoryImpl(this._srj5TQuestions);
  final Srj5QuestionsDataSource _srj5TQuestions;
  @override
  Future<AssessmentQuestions?> getQuestion(
      String cluster) async {
    final result = await _srj5TQuestions.getQuestion(cluster);
    final List<String> questionTextList = [];
    if (result.isNotEmpty) {
      final resultCluster = result[0]!.cluster!;
      final questionTextList =
          result.map((q) => q!.questionText!).toList();

      return AssessmentQuestions(
          cluster: resultCluster,
          questionText: questionTextList);
    }
    return null;
  }
}
