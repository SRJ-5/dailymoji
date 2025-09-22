import 'package:dailymoji/domain/repositories/user_repository.dart';

class InsertSurveyResponseUseCase {
  InsertSurveyResponseUseCase(this._userRepository);
  final UserRepository _userRepository;

  // Future<void> execute(UserProfile userProfile) async {
  //   return await _userRepository.insertUserProfile(userProfile);
  // }
}
