import 'package:dailymoji/data/data_sources/user_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:dailymoji/domain/entities/survey_response.dart';
import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._userDataSource);
  final UserDataSource _userDataSource;
  @override
  Future<SurveyResponse> getServeyResponses(
      SurveyResponse serveyResponse) {
    throw UnimplementedError();
  }

  @override
  Future<SurveyResponse> insertServeyResponses(
      SurveyResponse serveyResponse) {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> getUserProfile(UserProfile userProfile) {
    throw UnimplementedError();
  }

  @override
  Future<void> insertUserProfile(UserProfile userProfile) async {
    final userProfileDto =
        UserProfileDto.fromEntity(userProfile);
    await _userDataSource.insertUserProfile(userProfileDto);
  }
}
