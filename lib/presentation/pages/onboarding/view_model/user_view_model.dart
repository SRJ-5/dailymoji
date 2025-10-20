import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/enums/character_personality.dart';
import 'package:dailymoji/presentation/providers/user_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserState {
  final UserProfile? userProfile;
  final int characterNum;
  final bool step12;
  final bool step13;
  final List<int> step2Answers;

  UserState({
    required this.userProfile,
    this.characterNum = 0,
    this.step12 = false,
    this.step13 = false,
    List<int>? step2Answers,
  }) : step2Answers = step2Answers ??
            List.generate(
              10,
              (index) => index == 9 ? 0 : -1,
            );

  UserState copyWith({
    UserProfile? userProfile,
    int? characterNum,
    bool? step12,
    bool? step13,
    List<int>? step2Answers,
  }) {
    return UserState(
      userProfile: userProfile ?? this.userProfile,
      characterNum: characterNum ?? this.characterNum,
      step12: step12 ?? this.step12,
      step13: step13 ?? this.step13,
      step2Answers: step2Answers ?? List.from(this.step2Answers),
    );
  }
}

class UserViewModel extends Notifier<UserState> {
  @override
  UserState build() {
    return UserState(
      userProfile: UserProfile(
          id: null, createdAt: null, userNickNm: null, aiCharacter: null, characterNm: null, characterPersonality: null, onboardingScores: {}),
    );
  }

  Future<String?> googleLogin() async {
    final googleLogin = ref.read(googleLoginUseCaseProvider);
    final userId = await googleLogin.execute();
    if (userId != null) {
      state = state.copyWith(userProfile: state.userProfile?.copyWith(id: userId));
    }
    return userId;
  }

  Future<String?> appleLogin() async {
    final appleLogin = ref.read(appleLoginUseCaseProvider);
    final userId = await appleLogin.execute();
    if (userId != null) {
      state = state.copyWith(userProfile: state.userProfile?.copyWith(id: userId));
    }
    return userId;
  }

  Future<bool> getUserProfile(String userId) async {
    final userProfile = await ref.read(getUserProfileUseCaseProvider).execute(userId);
    if (userProfile?.userNickNm != null && userProfile?.characterNum != null) {
      state = state.copyWith(userProfile: userProfile);
      return true;
    } else {
      return false;
    }
  }

  Future<void> fetchInsertUser() async {
    // 저장 직전에 현재 state에 id가 있는지 다시 한번 확인
    final profileToInsert = state.userProfile;
    if (profileToInsert == null || profileToInsert.id == null) {
      print("Error: User ID is null. Cannot insert profile.");
      return;
    }

    final insertUserProfile = ref.read(insertUserProfileUseCaseProvider);
    // id가 확실히 포함된 profileToInsert를 전달
    await insertUserProfile.execute(profileToInsert);
  }

  void setAiName({required bool check, required String aiName}) {
    state = state.copyWith(step12: check, userProfile: state.userProfile?.copyWith(characterNm: aiName));
  }

  void setAiPersonality({required int selectNum, required String aiPersonality}) {
    state = state.copyWith(
        characterNum: selectNum, userProfile: state.userProfile?.copyWith(characterPersonality: aiPersonality, characterNum: selectNum));
  }

  void setUserNickName({required bool check, required String userNickName}) {
    state = state.copyWith(step13: check, userProfile: state.userProfile?.copyWith(userNickNm: userNickName));
  }

  void setAnswer({required int index, required int score}) {
    if (index < 0 || index >= state.step2Answers.length) return;
    final newAnswers = List<int>.from(state.step2Answers);
    newAnswers[index] = score;

    final currentScores = Map<String, dynamic>.from(state.userProfile?.onboardingScores ?? {});
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
    state = state.copyWith(step2Answers: newAnswers, userProfile: newSurveyResponse);
  }

  Future<void> updateUserNickNM({required String newUserNickNM}) async {
    final updateUserProfile = await ref.read(updateUserNickNameUseCaseProvider).execute(userNickNM: newUserNickNM, uuid: state.userProfile!.id!);
    state = state.copyWith(userProfile: updateUserProfile);
  }

  Future<void> updateCharacterNM({required String newCharacterNM}) async {
    final updateUserProfile = await ref.read(updateCharacterNameUseCaseProvider).execute(uuid: state.userProfile!.id!, characterNM: newCharacterNM);
    state = state.copyWith(userProfile: updateUserProfile);
  }

  Future<void> updateCharacterPersonality({required String newCharacterPersonality}) async {
    final updateUserProfile = await ref
        .read(updateCharacterPersonalityUseCaseProvider)
        .execute(uuid: state.userProfile!.id!, characterPersonality: newCharacterPersonality);
    state = state.copyWith(userProfile: updateUserProfile);
  }

// RIN: 피드백 제출하기 위해 chat view model에서 호출할 함수
  Future<void> submitSolutionFeedback({
    required String solutionId,
    String? sessionId,
    required String solutionType,
    required String feedback,
  }) async {
    final userId = state.userProfile?.id;
    if (userId == null) return;
    try {
      await ref.read(emotionRepositoryProvider).submitSolutionFeedback(
            userId: userId,
            solutionId: solutionId,
            sessionId: sessionId,
            solutionType: solutionType,
            feedback: feedback,
          );

      // 피드백 제출 후 사용자 프로필을 다시 불러오는 로직.
      // negative_tags가 즉시 반영되길 원한다면 유지
      await getUserProfile(userId);
    } catch (e) {
      print("Error in UserViewModel while submitting feedback: $e");
    }
  }

// RIN: 수면위생 팁을 가져오는 함수
  Future<String> fetchSleepHygieneTip() async {
    final profile = state.userProfile;
    if (profile == null) return "규칙적인 수면 습관을 가져보세요."; // Fallback

    final personalityDbValue = profile.characterPersonality != null
        ? CharacterPersonality.values
            .firstWhere((e) => e.myLabel == profile.characterPersonality, orElse: () => CharacterPersonality.probSolver)
            .dbValue
        : null;

    final tip = await ref.read(fetchSleepHygieneTipUseCaseProvider).execute(
          personality: personalityDbValue,
          userNickNm: profile.userNickNm,
        );
    return tip;
  }

  Future<String> fetchActionMission() async {
    final profile = state.userProfile;
    if (profile == null) return "잠시 자리에서 일어나 굳은 몸을 풀어보는 건 어때요?";

    final personalityDbValue = profile.characterPersonality != null
        ? CharacterPersonality.values
            .firstWhere((e) => e.myLabel == profile.characterPersonality, orElse: () => CharacterPersonality.probSolver)
            .dbValue
        : null;

    final mission = await ref.read(fetchActionMissionUseCaseProvider).execute(
          personality: personalityDbValue,
          userNickNm: profile.userNickNm,
        );
    return mission;
  }

  Future<void> logOut() async {
    await ref.read(logOutUseCaseProvider).execute();
  }

  Future<void> deleteAccount() async {
    final userId = state.userProfile!.id!;
    await ref.read(deletAccountUseCaseProvider).execute(userId);
  }

  Future<void> saveFcmTokenToSupabase(TargetPlatform platform) async {
    await ref.read(saveFcmTokenToSupabaseUseCaseProvider).execute(platform);
  }
}

final userViewModelProvider = NotifierProvider<UserViewModel, UserState>(() {
  return UserViewModel();
});
