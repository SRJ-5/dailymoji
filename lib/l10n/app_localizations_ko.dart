// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get continueButton => '계속하기';

  @override
  String get startButton => '시작하기';

  @override
  String get completeButton => '완료';

  @override
  String get cancelButton => '취소';

  @override
  String get confirmButton => '확인';

  @override
  String get enterAnything => '무엇이든 입력하세요';

  @override
  String get nextButton => '다음';

  @override
  String get loading => '로딩 중...';

  @override
  String errorOccurred(String error) {
    return '오류가 발생했습니다: $error';
  }

  @override
  String get languageSettings => '언어 설정';

  @override
  String get notice => '공지사항';

  @override
  String get termsOfService => '이용 약관';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get counselingCenter => '전문 상담 연결';

  @override
  String get pageIsPreparing => '준비중';

  @override
  String get srj5Test => '나의 감정 알기';

  @override
  String get preparingTitle => '곧 만나요!';

  @override
  String get preparingBody => '준비 중이에요';

  @override
  String get navHome => '홈';

  @override
  String get navReport => '리포트';

  @override
  String get navMy => '마이';

  @override
  String get breathingTitle => '함께 차분해지는\n호흡 연습을 해볼까요?';

  @override
  String get breathingStep1Title => 'Step 1.';

  @override
  String get breathingStep1Text => '코로 4초동안\n천천히 숨을 들이마셔요';

  @override
  String get breathingStep2Title => 'Step 2.';

  @override
  String get breathingStep2Text => '7초 동안 살짝 멈추고\n몸의 긴장을 느껴봐요';

  @override
  String get breathingStep3Title => 'Step 3.';

  @override
  String get breathingStep3Text => '코로 8초 동안\n부드럽게 내쉬어주세요';

  @override
  String breathingFinishText(String context) {
    return '잘 했어요!\n안정되셨다면 마무리할게요';
  }

  @override
  String get breathingDefaultFinishText => '잘 했어요!\n이제 일상에 가서도\n호흡을 이어가 보세요';

  @override
  String get tapToContinue => '화면을 탭해서 종료하세요';

  @override
  String botIsTyping(String characterName) {
    return '$characterName이(가) 입력하고 있어요...';
  }

  @override
  String get viewSolutionAgainDefault => '마음 관리 팁 다시 볼래!';

  @override
  String get viewBreathingAgain => '다시 호흡하러 가기';

  @override
  String get viewVideoAgain => '다시 영상 보러가기';

  @override
  String get viewMissionAgain => '다시 미션하러 가기';

  @override
  String get viewPomodoroAgain => '다시 뽀모도로 하러 가기';

  @override
  String get acceptSolution => '좋아, 해볼게!';

  @override
  String get declineSolution => '아니, 더 대화할래';

  @override
  String get getHelp => '도움받기';

  @override
  String get itsOkay => '괜찮아요';

  @override
  String get currentMyEmotion => '현재 나의 감정';

  @override
  String get chatDateFormat => 'yyyy년 MM월 dd일';

  @override
  String get feedbackThanks => '피드백을 주셔서 고마워요! 다음 마음 관리 팁에 꼭 참고할게요. 😊';

  @override
  String get fallbackEmojiQuestion => '어떤 일 때문에 그렇게 느끼셨나요?';

  @override
  String get fallbackAnalysisError => '죄송해요, 응답을 이해할 수 없었어요.';

  @override
  String get fallbackSolutionError => '마음 관리 팁을 제안하는 중에 문제가 발생했어요.';

  @override
  String get askVideoFeedback => '이번 영상은 어떠셨나요?';

  @override
  String get loginRequiredError => '로그인 정보가 없습니다.';

  @override
  String get loadMoreFailedError => '추가 메시지를 불러오는데 실패했어요.';

  @override
  String get solutionFeedbackQuestion => '이번 활동은 어땠나요?';

  @override
  String get solutionHelpful => '도움됨';

  @override
  String get solutionNotHelpful => '도움 안됨';

  @override
  String get solutionBlock => '이런 종류 그만 보기';

  @override
  String get loginFailed => '로그인에 실패했습니다. 다시 시도해주세요.';

  @override
  String get loginTermsPrefix => '가입 시 ';

  @override
  String get loginTermsSuffix => '과 ';

  @override
  String get loginPrivacySuffix => '에 동의하게 됩니다.';

  @override
  String get dailyEmotionManagement => '매일매일 감정 관리';

  @override
  String get myPageTitle => '마이페이지';

  @override
  String get customSettings => '맞춤 설정';

  @override
  String get characterSettings => '도우미 설정';

  @override
  String get information => '정보';

  @override
  String get etc => '기타';

  @override
  String get logout => '로그아웃';

  @override
  String get deleteAccount => '회원 탈퇴';

  @override
  String get confirmLogout => '로그아웃 하시겠어요?';

  @override
  String get confirmDeleteAccount => '정말 탈퇴하시겠어요?';

  @override
  String get confirmDeleteAccountBody => '탈퇴 시 모든 기록이 삭제되며, 복구할 수 없습니다.';

  @override
  String get nickname => '닉네임';

  @override
  String get characterName => '도우미 이름';

  @override
  String get characterSelect => '도우미 선택';

  @override
  String get editNickname => '닉네임 수정';

  @override
  String get editCharacterName => '도우미 이름 수정';

  @override
  String get nicknameLengthRule => ' • 2~10자만 사용 가능해요';

  @override
  String get myState => '나의 상태';

  @override
  String get onboarding1TitleUser => '나의 닉네임 설정';

  @override
  String get onboarding1TitleAI => '도우미 설정';

  @override
  String get onboarding1Finish => '좋아요!\n이제 다음 단계로 가볼까요?';

  @override
  String onboarding2Title(String userName) {
    return '현재 $userName의 감정 기록';
  }

  @override
  String get onboarding2Finish => '모든 준비 완료!\n함께 시작해 볼까요?';

  @override
  String get onboardingQuestion1 => '지난 2주 동안, 기분이\n가라앉거나, 우울했거나,\n절망적이었나요?';

  @override
  String get onboardingQuestion2 => '지난 2주 동안, 일에 흥미를 잃거나 즐거움을 느끼지 못했나요?';

  @override
  String get onboardingQuestion3 => '지난 2주 동안, 초조하거나 긴장되거나 불안감을 자주 느꼈나요?';

  @override
  String get onboardingQuestion4 => '지난 2주 동안,\n걱정을 멈추거나 조절하기 \n어려웠나요?';

  @override
  String get onboardingQuestion5 =>
      '최근 한 달, 통제할 수 없거나 예상치 못한 일 때문에 화가 나거나 속상했나요?';

  @override
  String get onboardingQuestion6 =>
      '지난 한 달 동안, 잠들기 \n어렵거나 자주 깨는 문제가 \n얼마나 있었나요?';

  @override
  String get onboardingQuestion7 => '전반적으로, 나는 내 \n자신에 대해 긍정적인 \n태도를 가지고 있나요?';

  @override
  String get onboardingQuestion8 => '직무/일상적인 과제 때문에 신체적, 정신적으로 지쳐 있다고 느끼나요?';

  @override
  String get onboardingQuestion9 => '일상적인 일을 끝내는 \n것을 잊거나, 마무리 \n못하는 경우가 있나요?';

  @override
  String get reportTitle => '리포트';

  @override
  String get mojiCalendar => '모지 달력';

  @override
  String get mojiChart => '모지 차트';

  @override
  String get monthlyReportDefaultSummary => '날짜를 선택하면 감정 요약을 볼 수 있어요.';

  @override
  String get monthlyReportLoadingSummary => '감정 기록을 요약하고 있어요...';

  @override
  String get monthlyReportFailedSummary => '요약을 불러오는 데 실패했어요.';

  @override
  String monthlyReportErrorSummary(String error) {
    return '오류가 발생했어요: $error';
  }

  @override
  String get monthlyReportNoRecord => '이 날은 기록이 없는 하루예요';

  @override
  String get checkChatHistory => '채팅 확인하기';

  @override
  String get weeklyReportTitle => '나의 2주간 감정 상태';

  @override
  String get avgEmotionScore => '평균 감정 점수';

  @override
  String get maxEmotionScore => '최고 감정 점수';

  @override
  String get minEmotionScore => '최저 감정 점수';

  @override
  String scoreUnit(String scoreValue) {
    return '$scoreValue점';
  }

  @override
  String getMonthlyReportSummaryTitle(String clusterName) {
    return '이 날의 가장 높은 감정은 \'$clusterName\'';
  }

  @override
  String solutionLoadFailed(String error) {
    return '마음 관리 팁을 불러오는 데 실패했습니다: $error';
  }

  @override
  String get unplayableSolution => '재생할 수 없는 마음 관리 팁 유형입니다.';

  @override
  String get clusterNegHigh => '불안/분노';

  @override
  String get clusterNegLow => '우울/무기력';

  @override
  String get clusterSleep => '불규칙 수면';

  @override
  String get clusterAdhd => '집중력 저하';

  @override
  String get clusterPositive => '평온/회복';

  @override
  String get clusterTotalScore => '종합 감정 점수';

  @override
  String get weeklyReportGScoreDescription =>
      '종합 감정 점수는 불안, 우울, 수면 등 여러 마음 상태를 종합하여 나의 전반적인 마음 컨디션을 보여주는 지표예요. 점수가 높고 낮음보다 더 중요한 것은, 꾸준한 기록을 통해 나의 감정 변화 흐름을 스스로 이해해 나가는 과정 그 자체랍니다.';

  @override
  String get descNegHigh =>
      '불안이나 스트레스 높아 보여요. 쉴 틈 없이 팽팽한 긴장감 속에서 마음이 많이 지쳤을 수 있어요. 나의 감정을 알아차리는 것만으로도 변화의 첫걸음이 될 수 있습니다.';

  @override
  String get descNegLow =>
      '마음의 에너지가 많이 소진된 모습이 보여요. 평소에 즐겁던 일도 무감각하게 느껴지고, 작은 일에도 큰 노력이 필요한 시기일 수 있습니다. 지금은 잠시 멈춰서 스스로를 돌봐달라는 뜻일지도 모릅니다.';

  @override
  String get descPositive =>
      '안정적이고 긍정적인 감정 상태를 잘 유지하고 계시는군요. 외부의 스트레스에도 마음의 중심을 지키는 힘, 즉 회복탄력성이 건강하게 작동하고 있다는 좋은 신호입니다. 이 평온한 감각을 충분히 만끽해 보세요.';

  @override
  String get descSleep =>
      '수면의 질이 다소 흔들리는 모습이 보이네요. 잠드는 것이 어렵거나, 잠든 후에도 자주 깨는 날들이 있었을 수 있습니다. 좋은 잠은 감정 회복의 가장 중요한 기반이 되기에, 꾸준히 수면 패턴을 살펴보는 것이 좋습니다.';

  @override
  String get descAdhd =>
      '주의가 쉽게 흩어지거나 여러 생각들로 마음이 분주한 날들이 있었던 것 같아요. 해야 할 일은 많은데 어디서부터 시작해야 할지 막막하게 느껴졌을 수 있습니다. 이는 의지의 문제가 아닌, 뇌의 실행 기능이 과부하된 자연스러운 상태일 수 있어요.';

  @override
  String get weeklyReportError => '에러: ';

  @override
  String get averageEmotionalScore => '평균 감정 점수';

  @override
  String get highestEmotionalScore => '최고 감정 점수';

  @override
  String get lowestEmotionalScore => '최저 감정 점수';

  @override
  String get checkEmotions => '나의 감정 알기';

  @override
  String get weekdaySun => '일';

  @override
  String get weekdayMon => '월';

  @override
  String get weekdayTue => '화';

  @override
  String get weekdayWed => '수';

  @override
  String get weekdayThu => '목';

  @override
  String get weekdayFri => '금';

  @override
  String get weekdaySat => '토';

  @override
  String get monthlyReportLoadFailed => '로드 실패: ';

  @override
  String get monthlyReportDateFormat => 'yyyy년 MM월';

  @override
  String get monthlyReportDayFormat => 'M월 d일 EEEE';

  @override
  String get negHighDescription => '최근 긴장감과 짜증, 분노 빈도를 살펴봐요';

  @override
  String get negLowDescription => '기분 저하와 의욕, 흥미 감소를 확인해요';

  @override
  String get adhdDescription => '산만함과 미루기 패턴을 점검해요';

  @override
  String get sleepDescription => '잠들기, 유지의 어려움과 수면의 질을 살펴봐요';

  @override
  String get positiveDescription => '마음의 안정감과 회복 탄력도를 확인해요';

  @override
  String get testAnswer1 => '전혀 느낀 적 없었어요';

  @override
  String get testAnswer2 => '한두 번 그런 기분이 있었어요';

  @override
  String get testAnswer3 => '일주일에 3~4일 정도 있었어요';

  @override
  String get testAnswer4 => '거의 매일 있었어요';

  @override
  String get startGuideText1 => '하루 감정을 기록하면\n';

  @override
  String get startGuideText2 => '기록한 감정을 기반으로\n';

  @override
  String get startGuideText3 => '캘린더의 ';

  @override
  String get middleGuideText1 => '나를 이해하는 리포트';

  @override
  String get middleGuideText2 => '나만의 마음 관리법';

  @override
  String get middleGuideText3 => '감정 히스토리';

  @override
  String get endGuideText1 => '가 쌓여요';

  @override
  String get endGuideText2 => '을 찾아보세요';

  @override
  String get endGuideText3 => '를 통해\n변화를 한눈에 확인하세요';
}
