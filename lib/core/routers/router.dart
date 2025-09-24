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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
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
      ),
      // ChatPage 라우트를 분리하여 extra를 받을 수 있도록 함
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final emotion = state.extra as String?; // extra에서 이모지 데이터 받기
          return ChatPage(emotionFromHome: emotion);
        },
      ),
      GoRoute(path: '/report', builder: (context, state) => ReportPage()),
      GoRoute(path: '/my', builder: (context, state) => MyPage(), routes: [
        GoRoute(
          path: 'info',
          builder: (context, state) => InfoPage(),
        )
      ]),
      GoRoute(
        path: '/breathing/:solutionId',
        builder: (context, state) {
          final solutionId = state.pathParameters['solutionId']!;
          return BreathingSolutionPage(solutionId: solutionId);
        },
      ),
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
