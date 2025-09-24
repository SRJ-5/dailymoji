import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class UpdateCharacterPersonalityUseCase {
  UpdateCharacterPersonalityUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<UserProfile> execute(
      {required String uuid,
      required String characterPersonality}) async {
    final result =
        await _userRepository.updateCharacterPersonality(
            uuid: uuid,
            characterPersonality: characterPersonality);
    return result;
  }
}
