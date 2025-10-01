import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class LogOutUseCase {
  LogOutUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<void> execute() async {
    return await _userRepository.logOut();
  }
}
