import 'package:dailymoji/domain/entities/user_profile.dart';
import 'package:dailymoji/domain/repositories/user_repository.dart';

class GetUserProfileUseCase {
  GetUserProfileUseCase(this._userRepository);
  final UserRepository _userRepository;

  // Future<void> execute(UserProfile userProfile) async {
  //   return await _userRepository.insertUserProfile(userProfile);
  // }
}
