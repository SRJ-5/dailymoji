import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

class DeleteAccountUseCase {
  DeleteAccountUseCase(this._userRepository);
  final UserProfileRepository _userRepository;

  Future<void> execute(String userId) async {
    return await _userRepository.deleteAccount(userId);
  }
}
