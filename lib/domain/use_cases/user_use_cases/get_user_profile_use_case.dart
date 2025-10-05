import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class GetUserProfileUseCase {
  GetUserProfileUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<UserProfile?> execute(String uuid) async {
    final result = await _userRepository.getUserProfile(uuid);
    return result;
  }
}
