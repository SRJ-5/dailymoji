import 'package:dailymoji/data/dtos/survey_response_dto.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';

abstract class UserDataSource {
  Future<void> insertUserProfile(UserProfileDto userProfileDto);
  Future<UserProfileDto> getUserProfile(
      UserProfileDto userProfileDto);
  Future<void> insertServeyResponses(
      ServeyResponseDto serveyResponseDto);
  Future<ServeyResponseDto> getServeyResponses(
      ServeyResponseDto serveyResponseDto);
}
