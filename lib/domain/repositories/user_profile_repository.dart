import 'package:dailymoji/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<String?> googleLogin();
  Future<String?> appleLogin();
  Future<void> insertUserProfile(UserProfile userProfile);
  Future<UserProfile?> getUserProfile(String uuid);
  Future<UserProfile> updateUserNickNM(
      {required String userNickNM, required String uuid});
  Future<UserProfile> updateCharacterNM(
      {required String uuid, required String characterNM});
  Future<UserProfile> updateCharacterPersonality(
      {required String uuid, required String characterPersonality});

  Future<String> fetchSleepHygieneTip({
    String? personality,
    String? userNickNm,
  });

  Future<String> fetchActionMission({
    String? personality,
    String? userNickNm,
  });

  Future<void> logOut();
  Future<void> deleteAccount(String userId);
}
