import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

// 수면위생 팁 조회
class FetchSleepHygieneTipUseCase {
  final UserProfileRepository repository;

  FetchSleepHygieneTipUseCase(this.repository);

  Future<String> execute({String? personality, String? userNickNm}) {
    return repository.fetchSleepHygieneTip(
      personality: personality,
      userNickNm: userNickNm,
    );
  }
}
