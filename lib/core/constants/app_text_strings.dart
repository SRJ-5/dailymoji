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
  static const String loading = '로딩 중...';
  static const String errorOccurred = '오류가 발생했습니다: %s'; // %s for error

  // Router
  static const String languageSettings = '언어 설정';
  static const String notice = '공지사항';
  static const String termsOfService = '이용 약관';
  static const String privacyPolicy = '개인정보 처리방침';
  static const String counselingCenter = '전문 상담 연결';
  static const String pageIsPreparing = '준비중';
  static const String srj5Test = '나의 감정 알기';
  static const String preparingTitle = '곧 만나요!';
  static const String preparingBody = '준비 중이에요';

// Bottom Navigation
  static const String navHome = '홈';
  static const String navReport = '리포트';
  static const String navMy = '마이';

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
  static const String viewSolutionAgainDefault = '솔루션 다시 볼래!';

  // 유형별 다시보기 텍스트
  static const String viewBreathingAgain = '다시 호흡하러 가기';
  static const String viewVideoAgain = '다시 영상 보러가기';
  static const String viewMissionAgain = '다시 미션하러 가기';
  static const String viewPomodoroAgain = '다시 뽀모도로 하러 가기';

  static const String acceptSolution = '좋아, 해볼게!';
  static const String declineSolution = '아니, 더 대화할래';
  static const String getHelp = '도움받기';
  static const String itsOkay = '괜찮아요';

  static const String currentMyEmotion = '현재 나의 감정';
  static const String chatDateFormat = 'yyyy년 MM월 dd일';
  static const String feedbackThanks = '피드백을 주셔서 고마워요! 다음 솔루션에 꼭 참고할게요. 😊';

  // Chat ViewModel Fallbacks & Messages
  static const String fallbackEmojiQuestion = '어떤 일 때문에 그렇게 느끼셨나요?';
  static const String fallbackAnalysisError = '죄송해요, 응답을 이해할 수 없었어요.';
  static const String fallbackSolutionError = '솔루션을 제안하는 중에 문제가 발생했어요.';
  static const String askVideoFeedback = '이번 영상은 어떠셨나요?';
  static const String loginRequiredError = '로그인 정보가 없습니다.';
  static const String loadMoreFailedError = '추가 메시지를 불러오는데 실패했어요.';

  // 피드백 기능 관련 문자열 추가
  static const String solutionFeedbackQuestion = '이번 활동은 어땠나요?';
  static const String solutionHelpful = '도움됨';
  static const String solutionNotHelpful = '도움 안됨';
  static const String solutionBlock = '이런 종류 그만 보기';

  // Login Page
  static const String loginFailed = '로그인에 실패했습니다. 다시 시도해주세요.';
  static const String loginTermsPrefix = '가입 시 ';
  static const String loginTermsSuffix = '과 ';
  static const String loginPrivacySuffix = '에 동의하게 됩니다.';
  static const String dailyEmotionManagement = '매일매일 감정 관리';

  // My Page
  static const String myPageTitle = '마이페이지';
  static const String customSettings = '맞춤 설정';
  static const String characterSettings = '도우미 설정';
  static const String information = '정보';
  static const String etc = '기타';
  static const String logout = '로그아웃';
  static const String deleteAccount = '회원 탈퇴';
  static const String confirmLogout = '로그아웃 하시겠어요?';
  static const String confirmDeleteAccount = '정말 탈퇴하시겠어요?';
  static const String confirmDeleteAccountBody =
      '탈퇴 시 모든 기록이 삭제되며, 복구할 수 없습니다.';
  static const String nickname = '닉네임';
  static const String characterName = '도우미 이름';
  static const String characterSelect = '도우미 선택';
  static const String editNickname = '닉네임 수정';
  static const String editCharacterName = '도우미 이름 수정';
  static const String nicknameLengthRule = ' • 2~10자만 사용 가능해요';
  static const String myState = '나의 상태';

  // Onboarding
  static const String onboarding1TitleUser = '나의 닉네임 설정';
  static const String onboarding1TitleAI = '도우미 설정';
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
    '일상적인 일을 끝내는 \n것을 잊거나, 마무리 \n못하는 경우가 있나요?',
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
  static const String checkChatHistory = '채팅 확인하기';
  static const String weeklyReportTitle = '나의 2주간 감정 상태';
  static const String avgEmotionScore = '평균 감정 점수';
  static const String maxEmotionScore = '최고 감정 점수';
  static const String minEmotionScore = '최저 감정 점수';
  static const String scoreUnit = '%s점'; // %s for score value

  // 의료 가이드라인-> RIN: 클러스터 유형에 따라 동적 제목을 생성하는 static 메서드 추가
  static String getMonthlyReportSummaryTitle({
    required String clusterName,
  }) {
    return "이 날의 가장 높은 감정은 '$clusterName'";
  }

  // Solution Page
  static const String solutionLoadFailed =
      '솔루션을 불러오는 데 실패했습니다: %s'; // %s for error
  static const String unplayableSolution = '재생할 수 없는 솔루션 유형입니다.';

  // Cluster Names
  static const String clusterNegHigh = '불안/분노';
  static const String clusterNegLow = '우울/무기력';
  static const String clusterSleep = '불규칙 수면';
  static const String clusterAdhd = '집중력 저하';
  static const String clusterPositive = '평온/회복';
  static const String clusterTotalScore = '종합 감정 점수';

  // cluster name in supabase
  static const String negLow = 'neg_low';
  static const String negHigh = 'neg_high';
  static const String adhd = 'adhd';
  static const String sleep = 'sleep';
  static const String positive = 'positive';

  static const String weeklyReportGScoreDescription =
      '종합 감정 점수는 불안, 우울, 수면 등 여러 감정 상태를 종합하여 나의 전반적인 마음 컨디션을 보여주는 지표예요. 점수가 높고 낮음보다 더 중요한 것은, 꾸준한 기록을 통해 나의 감정 변화 흐름을 스스로 이해해 나가는 과정 그 자체랍니다.';
  static const String descNegHigh =
      '불안이나 스트레스 수치가 높게 나타났네요. 쉴 틈 없이 팽팽한 긴장감 속에서 마음이 많이 지쳤을 수 있어요. 나의 감정을 알아차리는 것만으로도 변화의 첫걸음이 될 수 있습니다.';
  static const String descNegLow =
      '마음의 에너지가 많이 소진된 모습이 보여요. 평소에 즐겁던 일도 무감각하게 느껴지고, 작은 일에도 큰 노력이 필요한 시기일 수 있습니다. 지금은 잠시 멈춰서 스스로를 돌봐달라는 신호일지도 모릅니다.';
  static const String descPositive =
      '안정적이고 긍정적인 감정 상태를 잘 유지하고 계시는군요. 외부의 스트레스에도 마음의 중심을 지키는 힘, 즉 회복탄력성이 건강하게 작동하고 있다는 좋은 신호입니다. 이 평온한 감각을 충분히 만끽해 보세요.';
  static const String descSleep =
      '수면의 질이 다소 흔들리는 모습이 보이네요. 잠드는 것이 어렵거나, 잠든 후에도 자주 깨는 날들이 있었을 수 있습니다. 좋은 잠은 감정 회복의 가장 중요한 기반이 되기에, 꾸준히 수면 패턴을 살펴보는 것이 좋습니다.';
  static const String descAdhd =
      '주의가 쉽게 흩어지거나 여러 생각들로 마음이 분주한 날들이 있었던 것 같아요. 해야 할 일은 많은데 어디서부터 시작해야 할지 막막하게 느껴졌을 수 있습니다. 이는 의지의 문제가 아닌, 뇌의 실행 기능이 과부하된 자연스러운 상태일 수 있어요.';

  // weekly_report.dart 용
  static const String weeklyReportError = '에러: ';
  static const String averageEmotionalScore = "평균 감정 점수";
  static const String highestEmotionalScore = "최고 감정 점수";
  static const String lowestEmotionalScore = "최저 감정 점수";
  static const String checkEmotions = "감정 검사하기";

  // monthly_report.dart 용
  static const List<String> weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const String monthlyReportLoadFailed = '로드 실패: ';
  static const String monthlyReportDateFormat = 'yyyy년 MM월';
  static const String monthlyReportDayFormat = 'M월 d일 EEEE'; // 예: 10월 7일 월요일

  // select_srj5_test_page.dart 용
  static const String negHighDescription = '최근 긴장감과 짜증, 분노 빈도를 살펴봐요';
  static const String negLowDescription = '기분 저하와 의욕, 흥미 감소를 확인해요';
  static const String sleepDescription = '산만함과 미루기 패턴을 점검해요';
  static const String adhdDescription = '잠들기, 유지의 어려움과 수면의 질을 살펴봐요';
  static const String positiveDescription = '마음의 안정감과 회복 탄력도를 확인해요';

  // onboarding 및 srj5 test 응답 용
  static const List<String> testAnswerList = [
    '전혀 느낀 적 없었어요',
    '한두 번 그런 기분이 있었어요',
    '일주일에 3~4일 정도 있었어요',
    '거의 매일 있었어요'
  ];

  // guide Page RichText 용
  static const List<String> startGuideText = [
    '하루 감정을 기록하면\n',
    '기록한 감정을 기반으로\n',
    '캘린더의 '
  ];
  static const List<String> middleGuideText = [
    '나를 이해하는 리포트',
    '나만의 마음 관리법',
    '감정 히스토리'
  ];
  static const List<String> endGuideText = [
    '가 쌓여요',
    '을 찾아보세요',
    '를 통해\n변화를 한눈에 확인하세요'
  ];
}

// 클러스터 DB 값과 표시용 이름을 매핑하는 유틸리티 클래스 추가
class ClusterUtil {
  static const Map<String, String> displayNames = {
    'neg_high': AppTextStrings.clusterNegHigh,
    'neg_low': AppTextStrings.clusterNegLow,
    'sleep': AppTextStrings.clusterSleep,
    'ADHD': AppTextStrings.clusterAdhd,
    'positive': AppTextStrings.clusterPositive,
  };

  static String getDisplayName(String dbValue) {
    return displayNames[dbValue] ?? dbValue;
  }
}
