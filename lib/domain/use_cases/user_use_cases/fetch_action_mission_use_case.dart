import 'package:dailymoji/domain/repositories/user_profile_repository.dart';

// 행동 미션 조회를 위한 UseCase
class FetchActionMissionUseCase {
  final UserProfileRepository repository;

  FetchActionMissionUseCase(this.repository);

  Future<String> execute({String? personality, String? userNickNm}) {
    return repository.fetchActionMission(
      personality: personality,
      userNickNm: userNickNm,
    );
  }
}
