/// 솔루션 제안 타입
/// 
/// 안전 위기 상황에 사용할 제안 멘트를 관리
enum SolutionProposal {
  negLow(
    "neg_low",
    [
      "많이 힘들어 보여요. 지금 바로 누군가의 도움이 필요할 수 있어요.",
    ],
  ),
  negHigh(
    "neg_high",
    [
      "지금 감정이 스스로를 해치지 않도록 도움이 필요해요.",
    ],
  );

  final String key;
  final List<String> scripts;

  const SolutionProposal(this.key, this.scripts);
  
  /// 문자열로부터 SolutionProposal을 찾는 헬퍼 메서드
  static SolutionProposal? fromString(String key) {
    try {
      return SolutionProposal.values.firstWhere((e) => e.key == key);
    } catch (_) {
      return null;
    }
  }
}

