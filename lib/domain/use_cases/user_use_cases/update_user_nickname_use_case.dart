import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class UpdateUserNicknameUseCase {
  UpdateUserNicknameUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<UserProfile> execute(
      {required String userNickNM, required String uuid}) async {
    final result = await _userRepository.updateUserNickNM(
        userNickNM: userNickNM, uuid: uuid);
    return result;
  }
}
