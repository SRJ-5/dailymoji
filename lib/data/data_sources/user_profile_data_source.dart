import 'package:dailymoji/data/dtos/user_profile_dto.dart';

abstract class UserProfileDataSource {
  Future<void> insertUserProfile(UserProfileDto userProfileDto);
  Future<UserProfileDto> getUserProfile(
      UserProfileDto userProfileDto);
}
