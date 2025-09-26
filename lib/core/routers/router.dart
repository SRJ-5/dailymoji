// lib/core/routers/router.dart

import 'package:dailymoji/presentation/pages/character_setting/character_setting_page.dart';
import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:dailymoji/presentation/pages/info/info_page.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorkey,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            const PortraitPage(child: SplashPage()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => PortraitPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/onboarding1',
        pageBuilder: (context, state) =>
            PortraitPage(child: OnboardingPart1Page()),
      ),
      GoRoute(
        path: '/onboarding2',
        pageBuilder: (context, state) =>
            PortraitPage(child: OnboardingPart2Page()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => const PortraitPage(child: HomePage()),
      ),
      // ChatPage 라우트를 분리하여 extra를 받을 수 있도록 함
      GoRoute(
        path: '/chat',
        pageBuilder: (context, state) {
          final emotion = state.extra as String?; // extra에서 이모지 데이터 받기
          return PortraitPage(child: ChatPage(emotionFromHome: emotion));
        },
      ),
      GoRoute(
        path: '/report',
        pageBuilder: (context, state) =>
            const PortraitPage(child: ReportPage()),
      ),
      GoRoute(
        path: '/my',
        pageBuilder: (context, state) => PortraitPage(child: MyPage()),
        routes: [
          GoRoute(
            path: 'info',
            pageBuilder: (context, state) => PortraitPage(child: InfoPage()),
          ),
          GoRoute(
            path: 'characterSetting',
            pageBuilder: (context, state) =>
                const PortraitPage(child: CharacterSettingPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/breathing/:solutionId',
        pageBuilder: (context, state) {
          final solutionId = state.pathParameters['solutionId']!;
          return PortraitPage(
              child: BreathingSolutionPage(solutionId: solutionId));
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
