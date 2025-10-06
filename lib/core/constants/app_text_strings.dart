// RIN: 추후 언어팩 확장을 위해 하드코딩된 문자열을 AppTextStrings 상수로 대체!
import 'package:dailymoji/domain/enums/cluster_type.dart';
import 'package:dailymoji/domain/models/cluster_stats_models.dart';

class AppTextStrings {
  // Common
  static const String continueButton = '계속하기';
  static const String startButton = '시작하기';
  static const String completeButton = '완료';
  static const String cancelButton = '취소';
  static const String confirmButton = '확인';
  static const String enterAnything = '무엇이든 입력하세요';
  static const String nextButton = '다음';

  // Router
  static const String languageSettings = '언어 설정';
  static const String notice = '공지사항';
  static const String termsOfService = '이용 약관';
  static const String privacyPolicy = '개인정보 처리방침';
  static const String counselingCenter = '상담센터 연결';
  static const String pageIsPreparing = '준비중';

  // Breathing Solution Page
  static const String breathingTitle = '함께 차분해지는\n호흡 연습을 해볼까요?';
  static const String breathingStep1Title = 'Step 1.';
  static const String breathingStep1Text = '코로 4초동안\n숨을 들이마시고';
  static const String breathingStep2Title = 'Step 2.';
  static const String breathingStep2Text = '7초간 숨을\n머금은 뒤';
  static const String breathingStep3Title = 'Step 3.';
  static const String breathingStep3Text = '8초간 천천히\n내쉬어 봐!';
  static const String breathingFinishText =
      '잘 했어요!\n이제 %s에 가서도\n호흡을 이어가 보세요'; // %s for context
  static const String breathingDefaultFinishText =
      '잘 했어요!\n이제 일상에 가서도\n호흡을 이어가 보세요';
  static const String tapToContinue = '화면을 탭해서 다음으로 넘어가세요';

  // Chat Page
  static const String botIsTyping =
      '%s이(가) 입력하고 있어요...'; // %s for character name
  static const String viewSolutionAgain = '솔루션 다시 볼래!';
  static const String acceptSolution = '좋아, 해볼게!';
  static const String declineSolution = '아니, 더 대화할래';
  static const String getHelp = '도움받기';
  static const String itsOkay = '괜찮아요';

  // Chat ViewModel Fallbacks
  static const String fallbackEmojiQuestion = '어떤 일 때문에 그렇게 느끼셨나요?';
  static const String fallbackAnalysisError = '죄송해요, 응답을 이해할 수 없었어요.';
  static const String fallbackSolutionError = '솔루션을 제안하는 중에 문제가 발생했어요.';

  // Login Page
  static const String loginFailed = '로그인에 실패했습니다. 다시 시도해주세요.';
  static const String loginTermsPrefix = '가입 시 ';
  static const String loginTermsSuffix = '과 ';
  static const String loginPrivacySuffix = '에 동의하게 됩니다.';
  static const String dailyEmotionManagement = '매일매일 감정 관리';

  // My Page
  static const String myPageTitle = '마이페이지';
  static const String customSettings = '맞춤 설정';
  static const String characterSettings = '캐릭터 설정';
  static const String information = '정보';
  static const String etc = '기타';
  static const String logout = '로그아웃';
  static const String deleteAccount = '회원 탈퇴';
  static const String confirmLogout = '로그아웃 하시겠어요?';
  static const String confirmDeleteAccount = '정말 탈퇴하시겠어요?';
  static const String nickname = '닉네임';
  static const String characterName = '캐릭터 이름';
  static const String characterPersonality = '캐릭터 성격';
  static const String editNickname = '닉네임 수정';
  static const String editCharacterName = '캐릭터 이름 수정';
  static const String nicknameLengthRule = ' • 2~10자만 사용 가능해요';

  // Onboarding
  static const String onboarding1TitleUser = '나의 닉네임 설정';
  static const String onboarding1TitleAI = '캐릭터 설정';
  static const String onboarding1Finish = '좋아요!\n이제 다음 단계로 가볼까요?';
  static const String onboarding2Title = '현재 %s의 감정 기록'; // %s for user name
  static const String onboarding2Finish = '모든 준비 완료!\n함께 시작해 볼까요?';
  static const List<String> onboardingQuestions = [
    '지난 2주 동안, 기분이\n가라앉거나, 우울했거나,\n절망적이었나요?',
    '지난 2주 동안, 일에 흥미를 잃거나 즐거움을 느끼지 못했나요?',
    '지난 2주 동안, 초조하거나 긴장되거나 불안감을 자주 느꼈나요?',
    '지난 2주 동안,\n걱정을 멈추거나 조절하기 \n어려웠나요?',
    '최근 한 달, 통제할 수 없거나 예상치 못한 일 때문에 화가 나거나 속상했나요?',
    '지난 한 달 동안, 잠들기 \n어렵거나 자주 깨는 문제가 \n얼마나 있었나요?',
    '전반적으로, 나는 내 \n자신에 대해 긍정적인 \n태도를 가지고 있나요?',
    '직무/일상적인 과제 때문에 신체적, 정신적으로 지쳐 있다고 느끼나요?',
    '자주 일상적인 일을 끝내는 \n것을 잊거나, 마무리 \n못하는 경우가 있나요?',
  ];

  // Report Page
  static const String reportTitle = '리포트';
  static const String mojiCalendar = '모지 달력';
  static const String mojiChart = '모지 차트';
  static const String monthlyReportDefaultSummary = '날짜를 선택하면 감정 요약을 볼 수 있어요.';
  static const String monthlyReportLoadingSummary = '감정 기록을 요약하고 있어요...';
  static const String monthlyReportFailedSummary = '요약을 불러오는 데 실패했어요.';
  static const String monthlyReportErrorSummary =
      '오류가 발생했어요: %s'; // %s for error
  static const String monthlyReportNoRecord = '이 날은 기록이 없는 하루예요';
  static const String monthlyReportDominantEmotion =
      '이 날의 %s 감정이 %d점으로 가장 강렬했습니다.'; // %s for cluster, %d for score
  static const String checkChatHistory = '채팅 확인하기';
  static const String weeklyReportTitle = '나의 2주간 감정 상태';
  static const String weeklyReportGScoreDescription =
      '종합 감정 점수는 최근의 감정을 모아 보여주는 지표예요. 완벽히 좋은 점수일 필요는 없고, 그때그때의 마음을 솔직히 드러낸 기록이면 충분합니다. 수치보다 중요한 건, 당신이 꾸준히 스스로를 돌아보고 있다는 사실이에요.';
  static const String avgEmotionScore = '평균 감정 점수';
  static const String maxEmotionScore = '최고 감정 점수';
  static const String minEmotionScore = '최저 감정 점수';
  static const String scoreUnit = '%s점'; // %s for score value

  // Solution Page
  static const String solutionLoadFailed =
      '솔루션을 불러오는 데 실패했습니다: %s'; // %s for error

  // Cluster Names
  static const String clusterNegHigh = '불안/분노';
  static const String clusterNegLow = '우울/무기력';
  static const String clusterSleep = '불규칙 수면';
  static const String clusterAdhd = '집중력저하';
  static const String clusterPositive = '평온/회복';
  static const String clusterTotalScore = '종합 감정 점수';
}

// 🧡 클러스터 DB 값과 표시용 이름을 매핑하는 유틸리티 클래스 추가
class ClusterUtil {
  static const Map<ClusterType, String> displayNames = {
    ClusterType.negHigh: AppTextStrings.clusterNegHigh,
    ClusterType.negLow: AppTextStrings.clusterNegLow,
    ClusterType.sleep: AppTextStrings.clusterSleep,
    ClusterType.adhd: AppTextStrings.clusterAdhd,
    ClusterType.positive: AppTextStrings.clusterPositive,
  };

  static String getDisplayName(String dbValue) {
    // dbValue에 해당하는 ClusterType enum 멤버 찾기
    final clusterType = ClusterType.values.firstWhere(
      (e) => e.dbValue == dbValue,
      orElse: () => ClusterType.positive,
    );

    // 찾은 enum 멤버를 키로 사용하여 Map에서 값 가져오기
    return displayNames[clusterType] ?? dbValue;
  }
}
