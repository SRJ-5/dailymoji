import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @continueButton.
  ///
  /// In ko, this message translates to:
  /// **'계속하기'**
  String get continueButton;

  /// No description provided for @startButton.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get startButton;

  /// No description provided for @completeButton.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get completeButton;

  /// No description provided for @cancelButton.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancelButton;

  /// No description provided for @confirmButton.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirmButton;

  /// No description provided for @enterAnything.
  ///
  /// In ko, this message translates to:
  /// **'무엇이든 입력하세요'**
  String get enterAnything;

  /// No description provided for @nextButton.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get nextButton;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// Error message with placeholder for error details
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다: {error}'**
  String errorOccurred(String error);

  /// No description provided for @languageSettings.
  ///
  /// In ko, this message translates to:
  /// **'언어 설정'**
  String get languageSettings;

  /// No description provided for @notice.
  ///
  /// In ko, this message translates to:
  /// **'공지사항'**
  String get notice;

  /// No description provided for @termsOfService.
  ///
  /// In ko, this message translates to:
  /// **'이용 약관'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get privacyPolicy;

  /// No description provided for @counselingCenter.
  ///
  /// In ko, this message translates to:
  /// **'전문 상담 연결'**
  String get counselingCenter;

  /// No description provided for @pageIsPreparing.
  ///
  /// In ko, this message translates to:
  /// **'준비중'**
  String get pageIsPreparing;

  /// No description provided for @srj5Test.
  ///
  /// In ko, this message translates to:
  /// **'나의 감정 알기'**
  String get srj5Test;

  /// No description provided for @preparingTitle.
  ///
  /// In ko, this message translates to:
  /// **'곧 만나요!'**
  String get preparingTitle;

  /// No description provided for @preparingBody.
  ///
  /// In ko, this message translates to:
  /// **'준비 중이에요'**
  String get preparingBody;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navReport.
  ///
  /// In ko, this message translates to:
  /// **'리포트'**
  String get navReport;

  /// No description provided for @navMy.
  ///
  /// In ko, this message translates to:
  /// **'마이'**
  String get navMy;

  /// No description provided for @breathingTitle.
  ///
  /// In ko, this message translates to:
  /// **'함께 차분해지는\n호흡 연습을 해볼까요?'**
  String get breathingTitle;

  /// No description provided for @breathingStep1Title.
  ///
  /// In ko, this message translates to:
  /// **'Step 1.'**
  String get breathingStep1Title;

  /// No description provided for @breathingStep1Text.
  ///
  /// In ko, this message translates to:
  /// **'코로 4초동안\n천천히 숨을 들이마셔요'**
  String get breathingStep1Text;

  /// No description provided for @breathingStep2Title.
  ///
  /// In ko, this message translates to:
  /// **'Step 2.'**
  String get breathingStep2Title;

  /// No description provided for @breathingStep2Text.
  ///
  /// In ko, this message translates to:
  /// **'7초 동안 살짝 멈추고\n몸의 긴장을 느껴봐요'**
  String get breathingStep2Text;

  /// No description provided for @breathingStep3Title.
  ///
  /// In ko, this message translates to:
  /// **'Step 3.'**
  String get breathingStep3Title;

  /// No description provided for @breathingStep3Text.
  ///
  /// In ko, this message translates to:
  /// **'코로 8초 동안\n부드럽게 내쉬어주세요'**
  String get breathingStep3Text;

  /// No description provided for @breathingFinishText.
  ///
  /// In ko, this message translates to:
  /// **'잘 했어요!\n안정되셨다면 마무리할게요'**
  String breathingFinishText(String context);

  /// No description provided for @breathingDefaultFinishText.
  ///
  /// In ko, this message translates to:
  /// **'잘 했어요!\n이제 일상에 가서도\n호흡을 이어가 보세요'**
  String get breathingDefaultFinishText;

  /// No description provided for @tapToContinue.
  ///
  /// In ko, this message translates to:
  /// **'화면을 탭해서 종료하세요'**
  String get tapToContinue;

  /// No description provided for @botIsTyping.
  ///
  /// In ko, this message translates to:
  /// **'{characterName}이(가) 입력하고 있어요...'**
  String botIsTyping(String characterName);

  /// No description provided for @viewSolutionAgainDefault.
  ///
  /// In ko, this message translates to:
  /// **'마음 관리 팁 다시 볼래!'**
  String get viewSolutionAgainDefault;

  /// No description provided for @viewBreathingAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 호흡하러 가기'**
  String get viewBreathingAgain;

  /// No description provided for @viewVideoAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 영상 보러가기'**
  String get viewVideoAgain;

  /// No description provided for @viewMissionAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 미션하러 가기'**
  String get viewMissionAgain;

  /// No description provided for @viewPomodoroAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 뽀모도로 하러 가기'**
  String get viewPomodoroAgain;

  /// No description provided for @acceptSolution.
  ///
  /// In ko, this message translates to:
  /// **'좋아, 해볼게!'**
  String get acceptSolution;

  /// No description provided for @declineSolution.
  ///
  /// In ko, this message translates to:
  /// **'아니, 더 대화할래'**
  String get declineSolution;

  /// No description provided for @getHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움받기'**
  String get getHelp;

  /// No description provided for @itsOkay.
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get itsOkay;

  /// No description provided for @currentMyEmotion.
  ///
  /// In ko, this message translates to:
  /// **'현재 나의 감정'**
  String get currentMyEmotion;

  /// No description provided for @chatDateFormat.
  ///
  /// In ko, this message translates to:
  /// **'yyyy년 MM월 dd일'**
  String get chatDateFormat;

  /// No description provided for @feedbackThanks.
  ///
  /// In ko, this message translates to:
  /// **'피드백을 주셔서 고마워요! 다음 마음 관리 팁에 꼭 참고할게요. 😊'**
  String get feedbackThanks;

  /// No description provided for @fallbackEmojiQuestion.
  ///
  /// In ko, this message translates to:
  /// **'어떤 일 때문에 그렇게 느끼셨나요?'**
  String get fallbackEmojiQuestion;

  /// No description provided for @fallbackAnalysisError.
  ///
  /// In ko, this message translates to:
  /// **'죄송해요, 응답을 이해할 수 없었어요.'**
  String get fallbackAnalysisError;

  /// No description provided for @fallbackSolutionError.
  ///
  /// In ko, this message translates to:
  /// **'마음 관리 팁을 제안하는 중에 문제가 발생했어요.'**
  String get fallbackSolutionError;

  /// No description provided for @askVideoFeedback.
  ///
  /// In ko, this message translates to:
  /// **'이번 영상은 어떠셨나요?'**
  String get askVideoFeedback;

  /// No description provided for @loginRequiredError.
  ///
  /// In ko, this message translates to:
  /// **'로그인 정보가 없습니다.'**
  String get loginRequiredError;

  /// No description provided for @loadMoreFailedError.
  ///
  /// In ko, this message translates to:
  /// **'추가 메시지를 불러오는데 실패했어요.'**
  String get loadMoreFailedError;

  /// No description provided for @solutionFeedbackQuestion.
  ///
  /// In ko, this message translates to:
  /// **'이번 활동은 어땠나요?'**
  String get solutionFeedbackQuestion;

  /// No description provided for @solutionHelpful.
  ///
  /// In ko, this message translates to:
  /// **'도움됨'**
  String get solutionHelpful;

  /// No description provided for @solutionNotHelpful.
  ///
  /// In ko, this message translates to:
  /// **'도움 안됨'**
  String get solutionNotHelpful;

  /// No description provided for @solutionBlock.
  ///
  /// In ko, this message translates to:
  /// **'이런 종류 그만 보기'**
  String get solutionBlock;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했습니다. 다시 시도해주세요.'**
  String get loginFailed;

  /// No description provided for @loginTermsPrefix.
  ///
  /// In ko, this message translates to:
  /// **'가입 시 '**
  String get loginTermsPrefix;

  /// No description provided for @loginTermsSuffix.
  ///
  /// In ko, this message translates to:
  /// **'과 '**
  String get loginTermsSuffix;

  /// No description provided for @loginPrivacySuffix.
  ///
  /// In ko, this message translates to:
  /// **'에 동의하게 됩니다.'**
  String get loginPrivacySuffix;

  /// No description provided for @dailyEmotionManagement.
  ///
  /// In ko, this message translates to:
  /// **'매일매일 감정 관리'**
  String get dailyEmotionManagement;

  /// No description provided for @myPageTitle.
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get myPageTitle;

  /// No description provided for @customSettings.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 설정'**
  String get customSettings;

  /// No description provided for @characterSettings.
  ///
  /// In ko, this message translates to:
  /// **'도우미 설정'**
  String get characterSettings;

  /// No description provided for @information.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get information;

  /// No description provided for @etc.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get etc;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get deleteAccount;

  /// No description provided for @confirmLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃 하시겠어요?'**
  String get confirmLogout;

  /// No description provided for @confirmDeleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴하시겠어요?'**
  String get confirmDeleteAccount;

  /// No description provided for @confirmDeleteAccountBody.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 시 모든 기록이 삭제되며, 복구할 수 없습니다.'**
  String get confirmDeleteAccountBody;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @characterName.
  ///
  /// In ko, this message translates to:
  /// **'도우미 이름'**
  String get characterName;

  /// No description provided for @characterSelect.
  ///
  /// In ko, this message translates to:
  /// **'도우미 선택'**
  String get characterSelect;

  /// No description provided for @editNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 수정'**
  String get editNickname;

  /// No description provided for @editCharacterName.
  ///
  /// In ko, this message translates to:
  /// **'도우미 이름 수정'**
  String get editCharacterName;

  /// No description provided for @nicknameLengthRule.
  ///
  /// In ko, this message translates to:
  /// **' • 2~10자만 사용 가능해요'**
  String get nicknameLengthRule;

  /// No description provided for @myState.
  ///
  /// In ko, this message translates to:
  /// **'나의 상태'**
  String get myState;

  /// No description provided for @onboarding1TitleUser.
  ///
  /// In ko, this message translates to:
  /// **'나의 닉네임 설정'**
  String get onboarding1TitleUser;

  /// No description provided for @onboarding1TitleAI.
  ///
  /// In ko, this message translates to:
  /// **'도우미 설정'**
  String get onboarding1TitleAI;

  /// No description provided for @onboarding1Finish.
  ///
  /// In ko, this message translates to:
  /// **'좋아요!\n이제 다음 단계로 가볼까요?'**
  String get onboarding1Finish;

  /// No description provided for @onboarding2Title.
  ///
  /// In ko, this message translates to:
  /// **'현재 {userName}의 감정 기록'**
  String onboarding2Title(String userName);

  /// No description provided for @onboarding2Finish.
  ///
  /// In ko, this message translates to:
  /// **'모든 준비 완료!\n함께 시작해 볼까요?'**
  String get onboarding2Finish;

  /// No description provided for @onboardingQuestion1.
  ///
  /// In ko, this message translates to:
  /// **'지난 2주 동안, 기분이\n가라앉거나, 우울했거나,\n절망적이었나요?'**
  String get onboardingQuestion1;

  /// No description provided for @onboardingQuestion2.
  ///
  /// In ko, this message translates to:
  /// **'지난 2주 동안, 일에 흥미를 잃거나 즐거움을 느끼지 못했나요?'**
  String get onboardingQuestion2;

  /// No description provided for @onboardingQuestion3.
  ///
  /// In ko, this message translates to:
  /// **'지난 2주 동안, 초조하거나 긴장되거나 불안감을 자주 느꼈나요?'**
  String get onboardingQuestion3;

  /// No description provided for @onboardingQuestion4.
  ///
  /// In ko, this message translates to:
  /// **'지난 2주 동안,\n걱정을 멈추거나 조절하기 \n어려웠나요?'**
  String get onboardingQuestion4;

  /// No description provided for @onboardingQuestion5.
  ///
  /// In ko, this message translates to:
  /// **'최근 한 달, 통제할 수 없거나 예상치 못한 일 때문에 화가 나거나 속상했나요?'**
  String get onboardingQuestion5;

  /// No description provided for @onboardingQuestion6.
  ///
  /// In ko, this message translates to:
  /// **'지난 한 달 동안, 잠들기 \n어렵거나 자주 깨는 문제가 \n얼마나 있었나요?'**
  String get onboardingQuestion6;

  /// No description provided for @onboardingQuestion7.
  ///
  /// In ko, this message translates to:
  /// **'전반적으로, 나는 내 \n자신에 대해 긍정적인 \n태도를 가지고 있나요?'**
  String get onboardingQuestion7;

  /// No description provided for @onboardingQuestion8.
  ///
  /// In ko, this message translates to:
  /// **'직무/일상적인 과제 때문에 신체적, 정신적으로 지쳐 있다고 느끼나요?'**
  String get onboardingQuestion8;

  /// No description provided for @onboardingQuestion9.
  ///
  /// In ko, this message translates to:
  /// **'일상적인 일을 끝내는 \n것을 잊거나, 마무리 \n못하는 경우가 있나요?'**
  String get onboardingQuestion9;

  /// No description provided for @reportTitle.
  ///
  /// In ko, this message translates to:
  /// **'리포트'**
  String get reportTitle;

  /// No description provided for @mojiCalendar.
  ///
  /// In ko, this message translates to:
  /// **'모지 달력'**
  String get mojiCalendar;

  /// No description provided for @mojiChart.
  ///
  /// In ko, this message translates to:
  /// **'모지 차트'**
  String get mojiChart;

  /// No description provided for @monthlyReportDefaultSummary.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 선택하면 감정 요약을 볼 수 있어요.'**
  String get monthlyReportDefaultSummary;

  /// No description provided for @monthlyReportLoadingSummary.
  ///
  /// In ko, this message translates to:
  /// **'감정 기록을 요약하고 있어요...'**
  String get monthlyReportLoadingSummary;

  /// No description provided for @monthlyReportFailedSummary.
  ///
  /// In ko, this message translates to:
  /// **'요약을 불러오는 데 실패했어요.'**
  String get monthlyReportFailedSummary;

  /// No description provided for @monthlyReportErrorSummary.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했어요: {error}'**
  String monthlyReportErrorSummary(String error);

  /// No description provided for @monthlyReportNoRecord.
  ///
  /// In ko, this message translates to:
  /// **'이 날은 기록이 없는 하루예요'**
  String get monthlyReportNoRecord;

  /// No description provided for @checkChatHistory.
  ///
  /// In ko, this message translates to:
  /// **'채팅 확인하기'**
  String get checkChatHistory;

  /// No description provided for @weeklyReportTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 2주간 감정 상태'**
  String get weeklyReportTitle;

  /// No description provided for @avgEmotionScore.
  ///
  /// In ko, this message translates to:
  /// **'평균 감정 점수'**
  String get avgEmotionScore;

  /// No description provided for @maxEmotionScore.
  ///
  /// In ko, this message translates to:
  /// **'최고 감정 점수'**
  String get maxEmotionScore;

  /// No description provided for @minEmotionScore.
  ///
  /// In ko, this message translates to:
  /// **'최저 감정 점수'**
  String get minEmotionScore;

  /// No description provided for @scoreUnit.
  ///
  /// In ko, this message translates to:
  /// **'{scoreValue}점'**
  String scoreUnit(String scoreValue);

  /// No description provided for @getMonthlyReportSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 날의 가장 높은 감정은 \'{clusterName}\''**
  String getMonthlyReportSummaryTitle(String clusterName);

  /// No description provided for @solutionLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'마음 관리 팁을 불러오는 데 실패했습니다: {error}'**
  String solutionLoadFailed(String error);

  /// No description provided for @unplayableSolution.
  ///
  /// In ko, this message translates to:
  /// **'재생할 수 없는 마음 관리 팁 유형입니다.'**
  String get unplayableSolution;

  /// No description provided for @clusterNegHigh.
  ///
  /// In ko, this message translates to:
  /// **'불안/분노'**
  String get clusterNegHigh;

  /// No description provided for @clusterNegLow.
  ///
  /// In ko, this message translates to:
  /// **'우울/무기력'**
  String get clusterNegLow;

  /// No description provided for @clusterSleep.
  ///
  /// In ko, this message translates to:
  /// **'불규칙 수면'**
  String get clusterSleep;

  /// No description provided for @clusterAdhd.
  ///
  /// In ko, this message translates to:
  /// **'집중력 저하'**
  String get clusterAdhd;

  /// No description provided for @clusterPositive.
  ///
  /// In ko, this message translates to:
  /// **'평온/회복'**
  String get clusterPositive;

  /// No description provided for @clusterTotalScore.
  ///
  /// In ko, this message translates to:
  /// **'종합 감정 점수'**
  String get clusterTotalScore;

  /// No description provided for @weeklyReportGScoreDescription.
  ///
  /// In ko, this message translates to:
  /// **'종합 감정 점수는 불안, 우울, 수면 등 여러 마음 상태를 종합하여 나의 전반적인 마음 컨디션을 보여주는 지표예요. 점수가 높고 낮음보다 더 중요한 것은, 꾸준한 기록을 통해 나의 감정 변화 흐름을 스스로 이해해 나가는 과정 그 자체랍니다.'**
  String get weeklyReportGScoreDescription;

  /// No description provided for @descNegHigh.
  ///
  /// In ko, this message translates to:
  /// **'불안이나 스트레스 높아 보여요. 쉴 틈 없이 팽팽한 긴장감 속에서 마음이 많이 지쳤을 수 있어요. 나의 감정을 알아차리는 것만으로도 변화의 첫걸음이 될 수 있습니다.'**
  String get descNegHigh;

  /// No description provided for @descNegLow.
  ///
  /// In ko, this message translates to:
  /// **'마음의 에너지가 많이 소진된 모습이 보여요. 평소에 즐겁던 일도 무감각하게 느껴지고, 작은 일에도 큰 노력이 필요한 시기일 수 있습니다. 지금은 잠시 멈춰서 스스로를 돌봐달라는 뜻일지도 모릅니다.'**
  String get descNegLow;

  /// No description provided for @descPositive.
  ///
  /// In ko, this message translates to:
  /// **'안정적이고 긍정적인 감정 상태를 잘 유지하고 계시는군요. 외부의 스트레스에도 마음의 중심을 지키는 힘, 즉 회복탄력성이 건강하게 작동하고 있다는 좋은 신호입니다. 이 평온한 감각을 충분히 만끽해 보세요.'**
  String get descPositive;

  /// No description provided for @descSleep.
  ///
  /// In ko, this message translates to:
  /// **'수면의 질이 다소 흔들리는 모습이 보이네요. 잠드는 것이 어렵거나, 잠든 후에도 자주 깨는 날들이 있었을 수 있습니다. 좋은 잠은 감정 회복의 가장 중요한 기반이 되기에, 꾸준히 수면 패턴을 살펴보는 것이 좋습니다.'**
  String get descSleep;

  /// No description provided for @descAdhd.
  ///
  /// In ko, this message translates to:
  /// **'주의가 쉽게 흩어지거나 여러 생각들로 마음이 분주한 날들이 있었던 것 같아요. 해야 할 일은 많은데 어디서부터 시작해야 할지 막막하게 느껴졌을 수 있습니다. 이는 의지의 문제가 아닌, 뇌의 실행 기능이 과부하된 자연스러운 상태일 수 있어요.'**
  String get descAdhd;

  /// No description provided for @weeklyReportError.
  ///
  /// In ko, this message translates to:
  /// **'에러: '**
  String get weeklyReportError;

  /// No description provided for @averageEmotionalScore.
  ///
  /// In ko, this message translates to:
  /// **'평균 감정 점수'**
  String get averageEmotionalScore;

  /// No description provided for @highestEmotionalScore.
  ///
  /// In ko, this message translates to:
  /// **'최고 감정 점수'**
  String get highestEmotionalScore;

  /// No description provided for @lowestEmotionalScore.
  ///
  /// In ko, this message translates to:
  /// **'최저 감정 점수'**
  String get lowestEmotionalScore;

  /// No description provided for @checkEmotions.
  ///
  /// In ko, this message translates to:
  /// **'나의 감정 알기'**
  String get checkEmotions;

  /// No description provided for @weekdaySun.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get weekdaySun;

  /// No description provided for @weekdayMon.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In ko, this message translates to:
  /// **'화'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In ko, this message translates to:
  /// **'수'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In ko, this message translates to:
  /// **'목'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In ko, this message translates to:
  /// **'토'**
  String get weekdaySat;

  /// No description provided for @monthlyReportLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'로드 실패: '**
  String get monthlyReportLoadFailed;

  /// No description provided for @monthlyReportDateFormat.
  ///
  /// In ko, this message translates to:
  /// **'yyyy년 MM월'**
  String get monthlyReportDateFormat;

  /// No description provided for @monthlyReportDayFormat.
  ///
  /// In ko, this message translates to:
  /// **'M월 d일 EEEE'**
  String get monthlyReportDayFormat;

  /// No description provided for @negHighDescription.
  ///
  /// In ko, this message translates to:
  /// **'최근 긴장감과 짜증, 분노 빈도를 살펴봐요'**
  String get negHighDescription;

  /// No description provided for @negLowDescription.
  ///
  /// In ko, this message translates to:
  /// **'기분 저하와 의욕, 흥미 감소를 확인해요'**
  String get negLowDescription;

  /// No description provided for @adhdDescription.
  ///
  /// In ko, this message translates to:
  /// **'산만함과 미루기 패턴을 점검해요'**
  String get adhdDescription;

  /// No description provided for @sleepDescription.
  ///
  /// In ko, this message translates to:
  /// **'잠들기, 유지의 어려움과 수면의 질을 살펴봐요'**
  String get sleepDescription;

  /// No description provided for @positiveDescription.
  ///
  /// In ko, this message translates to:
  /// **'마음의 안정감과 회복 탄력도를 확인해요'**
  String get positiveDescription;

  /// No description provided for @testAnswer1.
  ///
  /// In ko, this message translates to:
  /// **'전혀 느낀 적 없었어요'**
  String get testAnswer1;

  /// No description provided for @testAnswer2.
  ///
  /// In ko, this message translates to:
  /// **'한두 번 그런 기분이 있었어요'**
  String get testAnswer2;

  /// No description provided for @testAnswer3.
  ///
  /// In ko, this message translates to:
  /// **'일주일에 3~4일 정도 있었어요'**
  String get testAnswer3;

  /// No description provided for @testAnswer4.
  ///
  /// In ko, this message translates to:
  /// **'거의 매일 있었어요'**
  String get testAnswer4;

  /// No description provided for @startGuideText1.
  ///
  /// In ko, this message translates to:
  /// **'하루 감정을 기록하면\n'**
  String get startGuideText1;

  /// No description provided for @startGuideText2.
  ///
  /// In ko, this message translates to:
  /// **'기록한 감정을 기반으로\n'**
  String get startGuideText2;

  /// No description provided for @startGuideText3.
  ///
  /// In ko, this message translates to:
  /// **'캘린더의 '**
  String get startGuideText3;

  /// No description provided for @middleGuideText1.
  ///
  /// In ko, this message translates to:
  /// **'나를 이해하는 리포트'**
  String get middleGuideText1;

  /// No description provided for @middleGuideText2.
  ///
  /// In ko, this message translates to:
  /// **'나만의 마음 관리법'**
  String get middleGuideText2;

  /// No description provided for @middleGuideText3.
  ///
  /// In ko, this message translates to:
  /// **'감정 히스토리'**
  String get middleGuideText3;

  /// No description provided for @endGuideText1.
  ///
  /// In ko, this message translates to:
  /// **'가 쌓여요'**
  String get endGuideText1;

  /// No description provided for @endGuideText2.
  ///
  /// In ko, this message translates to:
  /// **'을 찾아보세요'**
  String get endGuideText2;

  /// No description provided for @endGuideText3.
  ///
  /// In ko, this message translates to:
  /// **'를 통해\n변화를 한눈에 확인하세요'**
  String get endGuideText3;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
