import 'package:dailymoji/domain/repositories/user_repository.dart';

class GetSurveyResponseUseCase {
  GetSurveyResponseUseCase(this._userRepository);
  final UserRepository _userRepository;

  // Future<void> execute(UserProfile userProfile) async {
  //   return await _userRepository.insertUserProfile(userProfile);
  // }
}
