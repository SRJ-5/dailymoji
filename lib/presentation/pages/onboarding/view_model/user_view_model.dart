import 'package:dailymoji/domain/entities/survey_response.dart';
import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final UserProfile? userProfile;
  final SurveyResponse? surveyResponse;
  final bool step11;
  final bool step12;
  final bool step13;
  final bool step14;
  final List<bool> step2Answers;

  UserState({
    required this.userProfile,
    required this.surveyResponse,
    this.step11 = true,
    this.step12 = false,
    this.step13 = false,
    this.step14 = false,
    List<bool>? step2Answers,
  }) : step2Answers = step2Answers ??
            List.generate(
              10,
              (index) => index == 9 ? true : false,
            );

  UserState copyWith({
    UserProfile? userProfile,
    SurveyResponse? surveyResponse,
    bool? step11,
    bool? step12,
    bool? step13,
    bool? step14,
    List<bool>? step2Answers,
  }) {
    return UserState(
      userProfile: userProfile ?? this.userProfile,
      surveyResponse: surveyResponse ?? this.surveyResponse,
      step11: step11 ?? this.step11,
      step12: step12 ?? this.step12,
      step13: step13 ?? this.step13,
      step14: step14 ?? this.step14,
      step2Answers: step2Answers ?? List.from(this.step2Answers),
    );
  }
}

class UserViewModel extends Notifier<UserState> {
  @override
  UserState build() {
    return UserState(
        userProfile: UserProfile(
            id: null,
            createdAt: null,
            userId: null,
            userNickNm: null,
            aiCharacter: null,
            characterNm: null,
            characterPersonality: null),
        surveyResponse: SurveyResponse(
            id: null,
            userId: null,
            createdAt: null,
            onboardingScores: {}));
  }

  void setAiName({required bool check, required String aiName}) {
    state = state.copyWith(
        step12: check,
        userProfile:
            state.userProfile?.copyWith(characterNm: aiName));
  }

  void setAiPersonality(
      {required bool check, required String aiPersonality}) {
    state = state.copyWith(
        step13: check,
        userProfile: state.userProfile
            ?.copyWith(characterPersonality: aiPersonality));
  }

  void setUserNickName(
      {required bool check, required String userNickName}) {
    state = state.copyWith(
        step14: check,
        userProfile: state.userProfile
            ?.copyWith(userNickNm: userNickName));
  }

  void setAnswer(
      {required int index,
      required bool check,
      required int score}) {
    if (index < 0 || index >= state.step2Answers.length) return;
    final newAnswers = List<bool>.from(state.step2Answers);
    newAnswers[index] = check;

    final currentScores = Map<String, dynamic>.from(
        state.surveyResponse?.onboardingScores ?? {});
    currentScores['q${index + 1}'] = score;

    final newSurveyResponse = (state.surveyResponse ??
            SurveyResponse(
                id: null,
                userId: null,
                createdAt: null,
                onboardingScores: {}))
        .copyWith(onboardingScores: currentScores);
    state = state.copyWith(
        step2Answers: newAnswers,
        surveyResponse: newSurveyResponse);
  }
}

final userViewModelProvider =
    NotifierProvider<UserViewModel, UserState>(() {
  return UserViewModel();
});
