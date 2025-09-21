import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final UserProfileDto dto;
  final String aiName;
  final String aiPersonality;
  final String userNickName;
  final bool step11;
  final bool step12;
  final bool step13;
  final bool step14;
  final List<bool> step2Answers;

  OnboardingState({
    required this.dto,
    required this.aiName,
    required this.aiPersonality,
    required this.userNickName,
    this.step11 = true,
    this.step12 = false,
    this.step13 = false,
    this.step14 = false,
    List<bool>? step2Answers,
  }) : step2Answers = step2Answers ?? List.filled(9, false);

  OnboardingState copyWith({
    UserProfileDto? dto,
    String? aiName,
    String? aiPersonality,
    String? userNickName,
    bool? step11,
    bool? step12,
    bool? step13,
    bool? step14,
    List<bool>? step2Answers,
  }) {
    return OnboardingState(
      dto: dto ?? this.dto,
      aiName: aiName ?? this.aiName,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      userNickName: userNickName ?? this.userNickName,
      step11: step11 ?? this.step11,
      step12: step12 ?? this.step12,
      step13: step13 ?? this.step13,
      step14: step14 ?? this.step14,
      step2Answers: step2Answers ?? List.from(this.step2Answers),
    );
  }
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState(
      dto: UserProfileDto(),
      aiName: '',
      aiPersonality: '',
      userNickName: '',
    );
  }

  void setAiName({required bool check, required String aiName}) {
    state = state.copyWith(step12: check, aiName: aiName);
  }

  void setAiPersonality(
      {required bool check, required String aiPersonality}) {
    state = state.copyWith(
        step13: check, aiPersonality: aiPersonality);
  }

  void setUserNickName(
      {required bool check, required String userNickName}) {
    state = state.copyWith(
        step14: check, userNickName: userNickName);
  }

  void setAnswer({required int index, required bool check}) {
    if (index < 0 || index >= state.step2Answers.length) return;
    final newAnswers = List<bool>.from(state.step2Answers);
    newAnswers[index] = check;
    state = state.copyWith(step2Answers: newAnswers);
  }
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(() {
  return OnboardingViewModel();
});
