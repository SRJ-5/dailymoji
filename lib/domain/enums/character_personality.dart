/// 캐릭터 성격 타입
///
/// AI 챗봇의 성격 유형을 정의
enum CharacterPersonality {
  probSolver(
      "prob_solver", "차분하게 상황을 분석하고\n문제를 해결하는 친구", "문제 해결을 잘함"),
  warmHeart("warm_heart", "감정 표현이 풍부하고\n따뜻한 친구", "감정 풍부하고 따뜻함"),
  oddKind("odd_kind", "어딘가 엉뚱하지만 마음만은 따뜻한 친구", "엉뚱하지만 따뜻함"),
  balanced(
      "balanced", "따뜻함과 이성적인 사고를 모두 가진 친구", "따뜻함과 이성 모두 가짐");

  final String dbValue;
  final String onboardingLabel;
  final String myLabel;

  const CharacterPersonality(
      this.dbValue, this.onboardingLabel, this.myLabel);
}
