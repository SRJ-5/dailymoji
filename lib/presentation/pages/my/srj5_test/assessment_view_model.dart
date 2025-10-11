import 'package:dailymoji/domain/entities/assessment_questions.dart';
import 'package:dailymoji/presentation/providers/assessment_question_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssessmentState {
  final int clusterNum;
  final AssessmentQuestions? questionsList;
  AssessmentState(
      {required this.clusterNum, this.questionsList});

  AssessmentState copyWith({
    int? clusterNum,
  }) {
    return AssessmentState(
        clusterNum: clusterNum ?? this.clusterNum);
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

  Future<bool> getQuestion(String cluster) async {
    final result = await ref
        .read(getQuestionsUseCaseProvider)
        .excute(cluster);
    if (result != null) {
      state =
          AssessmentState(clusterNum: -1, questionsList: result);
      print('1@#!@# : ${state.questionsList!.questionText[0]}');
      return true;
    }
    print('111111111');
    return false;
  }
}

final assessmentViewModelProvider =
    NotifierProvider<AssessmentViewModel, AssessmentState>(() {
  return AssessmentViewModel();
});
