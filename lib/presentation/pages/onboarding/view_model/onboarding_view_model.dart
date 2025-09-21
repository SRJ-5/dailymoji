import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final UserProfileDto dto;
  final bool step11;
  final bool step12;
  final bool step13;

  OnboardingState(
      {required this.dto,
      this.step11 = true,
      this.step12 = false,
      this.step13 = false});

  OnboardingState copyWith({
    UserProfileDto? dto,
    bool? step11,
    bool? step12,
    bool? step13,
  }) {
    return OnboardingState(
      dto: dto ?? this.dto,
      step11: step11 ?? this.step11,
      step12: step12 ?? this.step12,
      step13: step13 ?? this.step13,
    );
  }
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState(dto: UserProfileDto());
  }

  void changeStep12(bool check) {
    state = state.copyWith(step12: check);
  }
}

final onboardingViewModelProvider =
    NotifierProvider<OnboardingViewModel, OnboardingState>(() {
  return OnboardingViewModel();
});
