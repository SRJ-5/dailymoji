import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/presentation/providers/user_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final UserProfile? userProfile;
  final bool step11;
  final bool step12;
  final bool step13;
  final bool step14;
  final List<bool> step2Answers;

  UserState({
    required this.userProfile,
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
    bool? step11,
    bool? step12,
    bool? step13,
    bool? step14,
    List<bool>? step2Answers,
  }) {
    return UserState(
      userProfile: userProfile ?? this.userProfile,
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
          userNickNm: null,
          aiCharacter: null,
          characterNm: null,
          characterPersonality: null,
          onboardingScores: {}),
    );
  }

  Future<String?> googleLogin() async {
    final googleLogin = ref.read(googleLoginUseCaseProvider);
    final userId = await googleLogin.execute();
    state = state.copyWith(
        userProfile: state.userProfile?.copyWith(id: userId));
    return userId;
  }

  Future<String?> appleLogin() async {
    final appleLogin = ref.read(appleLoginUseCaseProvider);
    final userId = await appleLogin.execute();
    state = state.copyWith(
        userProfile: state.userProfile?.copyWith(id: userId));
    return userId;
  }

  Future<bool> getUserProfile(String userId) async {
    final userProfile = await ref
        .read(getUserProfileUseCaseProvider)
        .execute(userId);
    if (userProfile?.userNickNm != null) {
      state = state.copyWith(userProfile: userProfile);
      return true;
    } else {
      return false;
    }
  }

  Future<void> fetchInsertUser(
      {required UserProfile userProfile}) async {
    final insertUserProfile =
        ref.read(insertUserProfileUseCaseProvider);
    await insertUserProfile.execute(userProfile);
  }

  void setAiName({required bool check, required String aiName}) {
    state = state.copyWith(
        step13: check,
        userProfile:
            state.userProfile?.copyWith(characterNm: aiName));
  }

  void setAiPersonality(
      {required bool check, required String aiPersonality}) {
    state = state.copyWith(
        step12: check,
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
        state.userProfile?.onboardingScores ?? {});
    currentScores['q${index + 1}'] = score;

    final newSurveyResponse = (state.userProfile ??
            UserProfile(
              id: null,
              createdAt: null,
              userNickNm: null,
              aiCharacter: null,
              characterNm: null,
              characterPersonality: null,
              onboardingScores: {},
            ))
        .copyWith(onboardingScores: currentScores);
    state = state.copyWith(
        step2Answers: newAnswers,
        userProfile: newSurveyResponse);
    print('survey: ${state.userProfile?.onboardingScores}');
  }

  Future<void> updateUserNickNM(
      {required String newUserNickNM}) async {
    final updateUserProfile = await ref
        .read(updateUserNickNameUseCaseProvider)
        .execute(
            userNickNM: newUserNickNM,
            uuid: state.userProfile!.id!);
    state = state.copyWith(userProfile: updateUserProfile);
  }

  Future<void> updateCharacterNM(
      {required String newCharacterNM}) async {
    final updateUserProfile = await ref
        .read(updateCharacterNameUseCaseProvider)
        .execute(
            uuid: state.userProfile!.id!,
            characterNM: newCharacterNM);
    state = state.copyWith(userProfile: updateUserProfile);
  }

  Future<void> updateCharacterPersonality(
      {required String newCharacterPersonality}) async {
    final updateUserProfile = await ref
        .read(updateCharacterPersonalityUseCaseProvider)
        .execute(
            uuid: state.userProfile!.id!,
            characterPersonality: newCharacterPersonality);
    state = state.copyWith(userProfile: updateUserProfile);
  }
}

final userViewModelProvider =
    NotifierProvider<UserViewModel, UserState>(() {
  return UserViewModel();
});
