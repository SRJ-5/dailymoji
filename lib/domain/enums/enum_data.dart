// 09.26 소린 추가:
// dbValue : 로컬에서 변동되어도 db값은 그대로 유지되어 안정성이 높음
enum Sender {
  user("user"),
  bot("bot");

  final String dbValue;
  const Sender(this.dbValue);
}

enum MessageType {
  normal("normal"),
  solution("solution"),
  analysis("analysis"),
  solutionProposal("solution_proposal"),
  image("image"),
  system("system");

  final String dbValue;
  const MessageType(this.dbValue);
}

enum CharacterPersonality {
  probSolver("문제 해결을 잘함", "prob_solver"),
  warmHeart("감정 풍부하고 따뜻함", "warm_heart"),
  oddKind("엉뚱하지만 따뜻함", "odd_kind"),
  balanced("따뜻함과 이성 모두 가짐", "balanced");

  final String label;
  final String dbValue;
  const CharacterPersonality(this.label, this.dbValue);
}
