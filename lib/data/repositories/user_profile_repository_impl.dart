import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl
    implements UserProfileRepository {
  UserProfileRepositoryImpl(this._userDataSource);
  final UserProfileDataSource _userDataSource;

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
