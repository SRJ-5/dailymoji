// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get continueButton => 'Continue';

  @override
  String get startButton => 'Start';

  @override
  String get completeButton => 'Done';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get enterAnything => 'Feel free to share anything...';

  @override
  String get nextButton => 'Next';

  @override
  String get loading => 'Loading...';

  @override
  String errorOccurred(String error) {
    return 'Oh dear, something went wrong: $error';
  }

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get notice => 'Announcements';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get counselingCenter => 'Support Helplines';

  @override
  String get pageIsPreparing => 'Coming Soon!';

  @override
  String get srj5Test => 'Understanding My Feelings';

  @override
  String get preparingTitle => 'Coming Soon!';

  @override
  String get preparingBody => 'Getting this ready for you...';

  @override
  String get navHome => 'Home';

  @override
  String get navReport => 'Report';

  @override
  String get navMy => 'Profile';

  @override
  String get breathingTitle => 'Calming Breath Exercise';

  @override
  String get breathingStep1Title => 'Step 1.';

  @override
  String get breathingStep1Text =>
      'Gently breathe in through your nose\nfor 4 seconds';

  @override
  String get breathingStep2Title => 'Step 2.';

  @override
  String get breathingStep2Text =>
      'Hold gently for 7 seconds,\nnoticing how your body feels';

  @override
  String get breathingStep3Title => 'Step 3.';

  @override
  String get breathingStep3Text =>
      'Slowly breathe out through your nose\nfor 8 seconds';

  @override
  String breathingFinishText(String context) {
    return 'You did great!\nWrap up when you feel ready.';
  }

  @override
  String get breathingDefaultFinishText =>
      'Wonderful job!\nTry to bring this calm breathing\ninto your day.';

  @override
  String get tapToContinue => 'Tap to finish';

  @override
  String botIsTyping(String characterName) {
    return '$characterName is typing...';
  }

  @override
  String get viewSolutionAgainDefault => 'Revisit Wellness Activity';

  @override
  String get viewBreathingAgain => 'Practice Breathing Again';

  @override
  String get viewVideoAgain => 'Watch Video Again';

  @override
  String get viewMissionAgain => 'Revisit Mission';

  @override
  String get viewPomodoroAgain => 'Start Pomodoro Again';

  @override
  String get acceptSolution => 'Okay, let\'s give it a try!';

  @override
  String get declineSolution => 'No thanks, let\'s chat more';

  @override
  String get getHelp => 'Get Support';

  @override
  String get itsOkay => 'It\'s okay';

  @override
  String get currentMyEmotion => 'How I\'m Feeling Now';

  @override
  String get chatDateFormat => 'MMMM dd, yyyy';

  @override
  String get feedbackThanks =>
      'Thanks so much for your feedback! It really helps improve future activities. 😊';

  @override
  String get fallbackEmojiQuestion =>
      'What\'s going on that made you feel this way?';

  @override
  String get fallbackAnalysisError =>
      'Oops, I didn\'t quite catch that. Could you try again?';

  @override
  String get fallbackSolutionError =>
      'Hmm, there was a little hiccup suggesting an activity.';

  @override
  String get askVideoFeedback => 'Was this video helpful?';

  @override
  String get loginRequiredError => 'Looks like you need to be logged in.';

  @override
  String get loadMoreFailedError => 'Couldn\'t load more messages.';

  @override
  String get solutionFeedbackQuestion => 'How did this activity feel for you?';

  @override
  String get solutionHelpful => 'Helpful';

  @override
  String get solutionNotHelpful => 'Not Helpful';

  @override
  String get solutionBlock => 'Less of this type, please';

  @override
  String get loginFailed => 'Login failed. Please give it another try.';

  @override
  String get loginTermsPrefix => 'By signing up, you agree to the ';

  @override
  String get loginTermsSuffix => ' and ';

  @override
  String get loginPrivacySuffix => '.';

  @override
  String get dailyEmotionManagement => 'Daily Emotion Check-in';

  @override
  String get myPageTitle => 'Profile';

  @override
  String get customSettings => 'Preferences';

  @override
  String get characterSettings => 'Buddy Settings';

  @override
  String get information => 'Information';

  @override
  String get etc => 'Other';

  @override
  String get logout => 'Log Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmLogout => 'Log out?';

  @override
  String get confirmDeleteAccount => 'Delete Account?';

  @override
  String get confirmDeleteAccountBody =>
      'This action is permanent and cannot be undone. All your data will be lost.';

  @override
  String get nickname => 'Nickname';

  @override
  String get characterName => 'Buddy Name';

  @override
  String get characterSelect => 'Choose Your Buddy';

  @override
  String get editNickname => 'Edit Nickname';

  @override
  String get editCharacterName => 'Edit Buddy Name';

  @override
  String get nicknameLengthRule => ' • Needs to be 2-10 characters';

  @override
  String get myState => 'My Status';

  @override
  String get onboarding1TitleUser => 'Set Your Nickname';

  @override
  String get onboarding1TitleAI => 'Set Up Your Buddy';

  @override
  String get onboarding1Finish => 'Awesome!\nReady for the next step?';

  @override
  String onboarding2Title(String userName) {
    return 'Checking in on $userName\'s feelings';
  }

  @override
  String get onboarding2Finish =>
      'All set!\nReady to start this journey together?';

  @override
  String get onboardingQuestion1 =>
      'Over the last 2 weeks,\nhave you often felt down,\ndepressed, or hopeless?';

  @override
  String get onboardingQuestion2 =>
      'Over the last 2 weeks,\nhave you had little interest\nor pleasure in doing things?';

  @override
  String get onboardingQuestion3 =>
      'Over the last 2 weeks,\nhave you frequently felt\nnervous, anxious, or on edge?';

  @override
  String get onboardingQuestion4 =>
      'Over the last 2 weeks,\nhave you been unable to stop\nor control worrying?';

  @override
  String get onboardingQuestion5 =>
      'In the last month,\nhave you been upset because of\nsomething that happened unexpectedly?';

  @override
  String get onboardingQuestion6 =>
      'In the last month,\nhow often have you had trouble\nfalling asleep or staying asleep?';

  @override
  String get onboardingQuestion7 =>
      'Generally speaking,\ndo you have a positive attitude\ntoward yourself?';

  @override
  String get onboardingQuestion8 =>
      'Do you feel physically or\nmentally worn out due to\nyour work or daily tasks?';

  @override
  String get onboardingQuestion9 =>
      'Do you sometimes forget\nor have trouble finishing\nyour routine tasks?';

  @override
  String get reportTitle => 'Report';

  @override
  String get mojiCalendar => 'Moji Calendar';

  @override
  String get mojiChart => 'Moji Chart';

  @override
  String get monthlyReportDefaultSummary =>
      'Select a date to see your emotion summary.';

  @override
  String get monthlyReportLoadingSummary =>
      'Putting together your emotion summary...';

  @override
  String get monthlyReportFailedSummary => 'Couldn\'t load the summary.';

  @override
  String monthlyReportErrorSummary(String error) {
    return 'An error occurred: $error';
  }

  @override
  String get monthlyReportNoRecord => 'No activity recorded';

  @override
  String get checkChatHistory => 'Review Chat';

  @override
  String get weeklyReportTitle => 'Your Emotional Patterns (14 Days)';

  @override
  String get avgEmotionScore => 'Average';

  @override
  String get maxEmotionScore => 'Peak';

  @override
  String get minEmotionScore => 'Lowest';

  @override
  String scoreUnit(String scoreValue) {
    return '$scoreValue';
  }

  @override
  String getMonthlyReportSummaryTitle(String clusterName) {
    return 'Your strongest emotion this day was \'$clusterName\'';
  }

  @override
  String solutionLoadFailed(String error) {
    return 'Oops, couldn\'t load the wellness activity: $error';
  }

  @override
  String get unplayableSolution => 'This wellness activity isn\'t playable.';

  @override
  String get clusterNegHigh => 'Anxiety/Anger';

  @override
  String get clusterNegLow => 'Depression/Lethargy';

  @override
  String get clusterSleep => 'Sleep Quality';

  @override
  String get clusterAdhd => 'Focus Difficulty';

  @override
  String get clusterPositive => 'Calmness/Recovery';

  @override
  String get clusterTotalScore => 'Overall Emotional Score';

  @override
  String get weeklyReportGScoreDescription =>
      'The Overall Emotional Score brings together different feelings like anxiety, mood, and sleep quality to give you a general sense of your well-being. Remember, it\'s less about the number being high or low, and more about noticing your own emotional rhythm through regular check-ins. It\'s all part of the journey of understanding yourself better!';

  @override
  String get descNegHigh =>
      'It seems like anxiety or stress might be running a bit high. Feeling constantly tense can be really draining. Just noticing these feelings is a wonderful first step toward finding a bit more ease.';

  @override
  String get descNegLow =>
      'Looks like your energy levels might be a bit low. Things that usually feel fun might seem less appealing, and even small things could feel like they take a lot of effort. Maybe it\'s a gentle sign to pause and give yourself some extra care?';

  @override
  String get descPositive =>
      'It\'s great to see you\'re maintaining a sense of calm and positivity! This suggests your inner resilience is strong, helping you navigate challenges. Take a moment to really soak in this feeling of balance.';

  @override
  String get descSleep =>
      'It seems like your sleep quality might have been a little inconsistent lately. Maybe falling asleep was tough, or you woke up during the night? Quality rest is so important for emotional balance, so gently keeping an eye on your sleep patterns can be really helpful.';

  @override
  String get descAdhd =>
      'Maybe there were days when focus felt scattered, or your mind felt extra busy? Sometimes it can feel overwhelming just figuring out where to start. Remember, this isn\'t about willpower – it can simply happen when our brain\'s planning center feels a bit overloaded.';

  @override
  String get weeklyReportError => 'Error: null';

  @override
  String get averageEmotionalScore => 'Average';

  @override
  String get highestEmotionalScore => 'Peak';

  @override
  String get lowestEmotionalScore => 'Lowest';

  @override
  String get checkEmotions => 'Explore My Feelings';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get monthlyReportLoadFailed => 'Load failed: null';

  @override
  String get monthlyReportDateFormat => 'MMMM yyyy';

  @override
  String get monthlyReportDayFormat => 'EEEE, MMMM d';

  @override
  String get negHighDescription =>
      'Let\'s gently review recent feelings of tension, irritation, or anger.';

  @override
  String get negLowDescription =>
      'Let\'s check in on mood, motivation levels, and interest in things.';

  @override
  String get adhdDescription =>
      'Let\'s look at any patterns of distraction or putting things off.';

  @override
  String get sleepDescription =>
      'Let\'s explore sleep quality and any trouble falling or staying asleep.';

  @override
  String get positiveDescription =>
      'Let\'s check in on your sense of inner calm and resilience.';

  @override
  String get testAnswer1 => 'Not at all';

  @override
  String get testAnswer2 => 'Several days';

  @override
  String get testAnswer3 => 'More than half the days';

  @override
  String get testAnswer4 => 'Nearly every day';

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
