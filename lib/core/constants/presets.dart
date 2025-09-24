class PresetIds {
  // 친구 모드
  static const String friendlyReply = "FRIENDLY_REPLY";

  // 일반 분석 및 솔루션 제안
  static const String solutionProposal = "SOLUTION_PROPOSAL";

  // 안전 위기 모드 (1차 검사)
  static const String safetyCrisisModal = "SAFETY_CRISIS_MODAL";

  // 2차 안전 장치 (세분화된 위기 유형)
  static const String safetyCrisisSelfHarm = "SAFETY_CRISIS_SELF_HARM";
  static const String safetyCrisisAngerAnxiety = "SAFETY_CRISIS_ANGER_ANXIETY";
  static const String safetyCheckIn = "SAFETY_CHECK_IN";

  // 사용자가 이모지만 보내면,
  // 백엔드는 EMOJI_REACTION 프리셋과 함께 "화나는 일이 있었나봐요?" 같은
  // 간단한 공감/질문을 보내야 함
  static const String emojiReaction = "EMOJI_REACTION";
}
