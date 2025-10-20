/// 메시지 타입
///
/// 채팅 메시지의 종류를 구분하기 위한 enum
enum MessageType {
  normal("normal"),
  solution("solution"),
  analysis("analysis"),
  solutionProposal("solution_proposal"),
  solutionFeedback("solution_feedback"), //RIN: 마음 관리 팁 피드백 요청 타입
  image("image"),
  system("system");

  final String dbValue;
  const MessageType(this.dbValue);
}
