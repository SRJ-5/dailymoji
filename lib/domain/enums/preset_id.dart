/// Preset ID 타입
///
/// AI 챗봇의 응답 프리셋 종류를 정의
enum PresetId {
  friendlyReply("FRIENDLY_REPLY"),
  solutionProposal("SOLUTION_PROPOSAL"),
  safetyCrisisModal("SAFETY_CRISIS_MODAL"),
  safetyCrisisSelfHarm("SAFETY_CRISIS_SELF_HARM"),
  safetyCrisisAngerAnxiety("SAFETY_CRISIS_ANGER_ANXIETY"),
  safetyCheckIn("SAFETY_CHECK_IN"),
  emojiReaction("EMOJI_REACTION"),
  adhdPreSolutionQuestion("ADHD_PRE_SOLUTION_QUESTION"),
  adhdAwaitingTaskDescription("ADHD_AWAITING_TASK_DESCRIPTION"),
  adhdTaskBreakdown("ADHD_TASK_BREAKDOWN");

  final String value;
  const PresetId(this.value);

  /// 문자열로부터 PresetId를 찾는 헬퍼 메서드
  static PresetId? fromString(String value) {
    try {
      return PresetId.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}
