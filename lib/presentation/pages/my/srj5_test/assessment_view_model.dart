import 'package:dailymoji/domain/entities/assessment_questions.dart';
import 'package:dailymoji/domain/entities/assessment_responses.dart';
import 'package:dailymoji/presentation/providers/assessment_question_providers.dart';
import 'package:dailymoji/presentation/providers/assessment_responses_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssessmentState {
  final int clusterNum;
  final AssessmentQuestions? questionsList;
  final AssessmentResponses? responses;
  final List<int>? questionScores;
  AssessmentState({
    required this.clusterNum,
    this.questionsList,
    this.responses,
    this.questionScores,
  });

  AssessmentState copyWith({
    int? clusterNum,
    AssessmentQuestions? questionsList,
    AssessmentResponses? responses,
    List<int>? questionScores,
  }) {
    return AssessmentState(
        clusterNum: clusterNum ?? this.clusterNum,
        questionsList: questionsList ?? this.questionsList,
        responses: responses ?? this.responses,
        questionScores: questionScores ?? this.questionScores);
  }
}

class AssessmentViewModel extends Notifier<AssessmentState> {
  @override
  AssessmentState build() {
    return AssessmentState(clusterNum: -1);
  }

  void onChangeClusterNum(int clusterNum) {
    state = AssessmentState(clusterNum: clusterNum);
  }

  Future<bool> getQuestion({
    required String cluster,
    required String clusterNM,
  }) async {
    final result = await ref
        .read(getQuestionsUseCaseProvider)
        .excute(cluster);
    if (result != null) {
      final length = result.questionCode.length;
      state = AssessmentState(
          clusterNum: -1,
          questionsList: AssessmentQuestions(
              cluster: result.cluster,
              questionText: result.questionText,
              clusterNM: clusterNM,
              questionCode: result.questionCode),
          questionScores: List.generate(
              length + 1, (index) => index == length ? 0 : -1));
      print('1@#!@# : ${state.questionsList!.questionText[0]}');
      return true;
    }
    print('111111111');
    return false;
  }

  void setTestAnswer({
    required int questionIndex,
    required int score,
  }) {
    if (questionIndex < 0 ||
        questionIndex >= state.questionScores!.length) return;
    final newAnswers = List<int>.from(state.questionScores!);
    newAnswers[questionIndex] = score;

    print(newAnswers);
    final currentScores = Map<String, dynamic>.from(
        state.responses?.responses ?? {});
    currentScores[state
        .questionsList!.questionCode[questionIndex]] = score;

    print(currentScores);
    state = state.copyWith(
        questionScores: newAnswers,
        responses: AssessmentResponses(
          responses: currentScores,
        ));
    print(state.questionScores);
  }

  Future<void> submitAssessment(
      String userId, String clusterNM) async {
    final assessmentResult = AssessmentResponses(
        userId: userId,
        clusterNM: clusterNM,
        responses: state.responses!.responses);
    if (assessmentResult.userId == null ||
        assessmentResult.clusterNM == null ||
        assessmentResult.responses == null) {
      print(
          "Error: assessment responses is null. Cannot save assessment responses.");
      return;
    }
    await ref
        .read(submitAssessmentUseCaseProvider)
        .excute(assessmentResult);
  }
}

final assessmentViewModelProvider =
    NotifierProvider<AssessmentViewModel, AssessmentState>(() {
  return AssessmentViewModel();
});
