import 'package:dailymoji/data/dtos/user_profile_dto.dart';

abstract class UserProfileDataSource {
  Future<String?> googleLogin();
  Future<String?> appleLogin();
  Future<void> insertUserProfile(UserProfileDto userProfileDto);
  Future<UserProfileDto?> getUserProfile(String uuid);
  Future<UserProfileDto> updateUserNickNM(
      {required String userNickNM, required String uuid});
  Future<UserProfileDto> updateCharacterNM(
      {required String uuid, required String characterNM});
  Future<UserProfileDto> updateCharacterPersonality(
      {required String uuid, required String characterPersonality});

// RIN: 솔루션 피드백 제출
  Future<void> submitSolutionFeedback({
    required String userId,
    required String solutionId,
    String? sessionId,
    required String solutionType,
    required String feedback,
  });

  // RIN: 부정적 태그 추가
  Future<void> addNegativeTags({
    required String userId,
    required List<String> tags,
  });

  Future<String> fetchSleepHygieneTip({
    String? personality,
    String? userNickNm,
  });

  Future<void> logOut();
  Future<void> deleteAccount(String userId);
}
