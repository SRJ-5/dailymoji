enum CharacterPersonality {
  probSolver("문제 해결을 잘함", "prob_solver"),
  warmHeart("감정 풍부하고 따뜻함", "warm_heart"),
  oddKind("엉뚱하지만 따뜻함", "odd_kind"),
  balanced("따뜻함과 이성 모두 가짐", "balanced");

  final String label;
  final String dbValue;
  const CharacterPersonality(this.label, this.dbValue);
}
