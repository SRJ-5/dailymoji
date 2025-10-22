import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:flutter/material.dart';

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
      {required String uuid,
      required String characterPersonality});

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
  Future<void> saveFcmTokenToSupabase(
      {required TargetPlatform platform,
      required String userId});
}
