import 'package:dailymoji/presentation/pages/my/character_setting/character_setting_page.dart';
import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:dailymoji/presentation/pages/my/privacy_policy/privacy_policy_page.dart';
import 'package:dailymoji/presentation/pages/preparing/preparing_page.dart';
import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:dailymoji/presentation/pages/my/my_page.dart';
import 'package:dailymoji/presentation/pages/report/report_page.dart';
import 'package:dailymoji/presentation/pages/solution/solution_page.dart';
import 'package:dailymoji/presentation/pages/breathing_solution/breathing_solution_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part1_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part2_page.dart';
import 'package:dailymoji/presentation/pages/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorkey,
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
        builder: (context, state) => HomePage(),
        routes: [
          GoRoute(
            path: '/chat',
            builder: (context, state) {
              final extraData = state.extra as Object?;
              Map<String, dynamic>? navData;

              if (extraData is Map<String, dynamic>) {
                navData = extraData;
              }

              return ChatPage(
                navigationData: navData,
              );
            },
          ),
        ],
      ),
      // ChatPage 라우트를 분리하여 extra를 받을 수 있도록 함
      GoRoute(
          path: '/report',
          builder: (context, state) => ReportPage(),
          routes: [
            GoRoute(
              path: '/chat',
              builder: (context, state) {
                // extra를 Object?로 받아 유연하게 처리
                // 이모지(이미지)데이터 (홈), 텍스트 데이터 (솔루션)
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

                return ChatPage(
                  emotionFromHome: emotion,
                  navigationData: navData,
                  targetDate: targetDate,
                );
              },
            ),
          ]),
      GoRoute(
        path: '/my',
        builder: (context, state) => MyPage(),
      ),
      GoRoute(
        path: '/privacyPolicy',
        builder: (context, state) => PrivacyPolicyPage(),
      ),
      GoRoute(
          path: '/prepare/:title',
          builder: (context, state) {
            final title = state.pathParameters["title"] ?? "";
            return PreparingPage(title);
          }),
      GoRoute(
          path: '/characterSetting',
          builder: (context, state) => CharacterSettingPage()),
      GoRoute(
        path: '/breathing/:solutionId',
        builder: (context, state) {
          final solutionId = state.pathParameters['solutionId']!;
          return BreathingSolutionPage(solutionId: solutionId);
        },
      ),
      // SolutionPage는 가로모드를 사용하므로 PortraitPage를 적용하지 않습니다.
      GoRoute(
        path: '/solution/:solutionId',
        builder: (context, state) {
          final solutionId = state.pathParameters['solutionId']!;
          return SolutionPage(solutionId: solutionId);
        },
      ),
    ],
  );
});
