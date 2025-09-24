import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class UpdateCharacterNameUseCase {
  UpdateCharacterNameUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<UserProfile> execute(
      {required String uuid,
      required String characterNM}) async {
    final result = await _userRepository.updateCharacterNM(
        uuid: uuid, characterNM: characterNM);
    return result;
  }
}
