import 'package:dailymoji/data/data_sources/user_profile_data_source.dart';
import 'package:dailymoji/data/dtos/user_profile_dto.dart';
import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl
    implements UserProfileRepository {
  UserProfileRepositoryImpl(this._userDataSource);
  final UserProfileDataSource _userDataSource;

  @override
  Future<String?> appleLogin() async {
    return await _userDataSource.appleLogin();
  }

  @override
  Future<String?> googleLogin() async {
    return await _userDataSource.googleLogin();
  }

  @override
  Future<UserProfile?> getUserProfile(String uuid) async {
    final result = await _userDataSource.getUserProfile(uuid);
    if (result != null) {
      return result.toEntity();
    } else {
      return null;
    }
  }

  @override
  Future<void> insertUserProfile(UserProfile userProfile) async {
    final userProfileDto =
        UserProfileDto.fromEntity(userProfile);
    await _userDataSource.insertUserProfile(userProfileDto);
  }

  @override
  Future<UserProfile> updateUserNickNM(
      {required String userNickNM, required String uuid}) async {
    final result = await _userDataSource.updateUserNickNM(
        userNickNM: userNickNM, uuid: uuid);
    return result.toEntity();
  }

  @override
  Future<UserProfile> updateCharacterNM(
      {required String uuid,
      required String characterNM}) async {
    final result = await _userDataSource.updateCharacterNM(
        uuid: uuid, characterNM: characterNM);
    return result.toEntity();
  }

  @override
  Future<UserProfile> updateCharacterPersonality(
      {required String uuid,
      required String characterPersonality}) async {
    final result =
        await _userDataSource.updateCharacterPersonality(
            uuid: uuid,
            characterPersonality: characterPersonality);
    return result.toEntity();
  }
}
