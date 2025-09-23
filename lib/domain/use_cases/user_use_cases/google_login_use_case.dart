import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class GoogleLoginUseCase {
  GoogleLoginUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<String?> execute() async {
    return await _userRepository.googleLogin();
  }
}
