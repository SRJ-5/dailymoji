import 'package:dailymoji/domain/entities/survey_response.dart';
import 'package:dailymoji/domain/entities/user_profile.dart';

abstract class UserRepository {
  Future<void> insertUserProfile(UserProfile userProfile);
  Future<UserProfile> getUserProfile(UserProfile userProfile);
  Future<void> insertServeyResponses(
      SurveyResponse serveyResponseDto);
  Future<SurveyResponse> getServeyResponses(
      SurveyResponse serveyResponseDto);
}
