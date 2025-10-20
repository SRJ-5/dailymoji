import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/presentation/pages/counseling/counseling_page.dart';
import 'package:dailymoji/presentation/pages/my/character_setting/background_setting_page.dart';
import 'package:dailymoji/presentation/pages/my/character_setting/character_setting_page.dart';
import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:dailymoji/presentation/pages/my/delete_account/delete_account_page.dart';
import 'package:dailymoji/presentation/pages/my/privacy_policy/info_web_view_page.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/assessment_page.dart';
import 'package:dailymoji/presentation/pages/my/srj5_test/widgets/srj5_test_page.dart';
import 'package:dailymoji/presentation/pages/preparing/preparing_page.dart';
import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:dailymoji/presentation/pages/my/my_page.dart';
import 'package:dailymoji/presentation/pages/report/report_page.dart';
import 'package:dailymoji/presentation/pages/solution/solution_page.dart';
import 'package:dailymoji/presentation/pages/breathing_solution/breathing_solution_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part1_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part2_page.dart';
import 'package:dailymoji/presentation/pages/splash/splash_page.dart';
import 'package:dailymoji/presentation/widgets/portrait_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();
final routeObserverProvider =
    Provider((_) => RouteObserver<ModalRoute<void>>());

final routerProvider = Provider<GoRouter>((ref) {
  final routeObserver = ref.watch(routeObserverProvider);

  return GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorkey,
    observers: [routeObserver],
    routes: [
      GoRoute(path: '/', builder: (context, state) => SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(
          path: '/onboarding1',
          builder: (context, state) => OnboardingPart1Page()),
      GoRoute(
          path: '/onboarding2',
          builder: (context, state) => OnboardingPart2Page()),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => const PortraitPage(child: HomePage()),
        routes: [
          GoRoute(
            path: 'chat',
            pageBuilder: (context, state) {
              // extra를 Object?로 받아 유연하게 처리
              // 이모지(이미지)데이터 (홈), 텍스트 데이터 (마음 관리 팁)
              final extraData = state.extra as Object?;
              String? emotion;
              Map<String, dynamic>? navData;
              DateTime? targetDate;

              if (extraData is String) {
                emotion = extraData;
              } else if (extraData is Map<String, dynamic>) {
                navData = extraData;
              } else if (extraData is DateTime) {
                targetDate = extraData;
              }

              return PortraitPage(
                child: ChatPage(
                  emotionFromHome: emotion,
                  navigationData: navData,
                  targetDate: targetDate,
                ),
              );
            },
          ),
          GoRoute(
            path: 'background_setting',
            pageBuilder: (context, state) =>
                const PortraitPage(child: BackgroundSettingPage()),
          ),
        ],
      ),

      GoRoute(
          path: '/report',
          pageBuilder: (context, state) =>
              const PortraitPage(child: ReportPage()),
          routes: [
            GoRoute(
              path: 'chat',
              pageBuilder: (context, state) {
                // extra를 Object?로 받아 유연하게 처리
                // 이모지(이미지)데이터 (홈), 텍스트 데이터 (마음 관리 팁)
                final extraData = state.extra as Object?;
                String? emotion;
                Map<String, dynamic>? navData;
                DateTime? targetDate;

                if (extraData is String) {
                  emotion = extraData;
                } else if (extraData is Map<String, dynamic>) {
                  navData = extraData;
                } else if (extraData is DateTime) {
                  targetDate = extraData;
                }

                return PortraitPage(
                  child: ChatPage(
                    emotionFromHome: emotion,
                    navigationData: navData,
                    targetDate: targetDate,
                  ),
                );
              },
            ),
          ]),
      GoRoute(
        path: '/my',
        pageBuilder: (context, state) => PortraitPage(child: MyPage()),
      ),
      // TODO: 아래에 코드로 합쳐서 진행하였음 확인 후 필요없으면 삭제
      // GoRoute(
      //   path: '/privacyPolicy',
      //   pageBuilder: (context, state) =>
      //       PortraitPage(child: PrivacyPolicyPage()),
      // ),
      GoRoute(
          // TODO: prepare 경로 다른 이름을 수정해야 할듯 webView라든가?
          // 일단 info로 경로 이름 수정
          path: '/info/:title',
          builder: (context, state) {
            final title = state.pathParameters["title"] ?? "";
            switch (title) {
              case AppTextStrings.languageSettings:
                return PreparingPage(title);
              case AppTextStrings.notice:
              case AppTextStrings.termsOfService:
              case AppTextStrings.privacyPolicy:
                return InfoWebViewPage(title: title);
              case AppTextStrings.counselingCenter:
                return CounselingPage();
              case AppTextStrings.srj5Test:
                return AssessmentPage();
              default:
                return PreparingPage(AppTextStrings.pageIsPreparing);
            }
            // TODO: 위에 코드로 합쳐서 진행하였음 확인 후 필요없으면 삭제
            // if (title == "공지사항") {
            //   return PreparingPage(title);
            // } else if
            // return PrivacyPolicyPage();
          }),
      // TODO: 준비중 페이지는 따로 빼놓음
      GoRoute(
        path: '/deleteAccount',
        builder: (context, state) {
          return DeleteAccountPage();
        },
      ),
      GoRoute(
        path: '/prepare/:title',
        builder: (context, state) {
          final title = state.pathParameters["title"] ?? "";
          return PreparingPage(title);
        },
      ),
      GoRoute(
          path: '/characterSetting',
          builder: (context, state) => CharacterSettingPage()),
      GoRoute(
        path: '/breathing/:solutionId',
        pageBuilder: (context, state) {
          final solutionId = state.pathParameters['solutionId']!;
          final sessionId = state.uri.queryParameters['sessionId'];
          final isReview = state.uri.queryParameters['isReview'] == 'true';

          return PortraitPage(
              child: BreathingSolutionPage(
                  solutionId: solutionId,
                  sessionId: sessionId,
                  isReview: isReview));
        },
      ),
      // SolutionPage는 가로모드를 사용하므로 PortraitPage를 적용하지 않습니다.
      GoRoute(
        path: '/solution/:solutionId',
        builder: (context, state) {
          final solutionId = state.pathParameters['solutionId']!;
          final sessionId = state.uri.queryParameters['sessionId'];

          final isReview = state.uri.queryParameters['isReview'] == 'true';
          return SolutionPage(
              solutionId: solutionId, sessionId: sessionId, isReview: isReview);
        },
      ),
      GoRoute(
        path: '/srj5_test',
        builder: (context, state) {
          return Srj5TestPage();
        },
      )
    ],
  );
});
