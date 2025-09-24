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
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(
        path: '/', builder: (context, state) => SplashPage()),
    GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage()),
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
              path: '/ChatPage',
              builder: (context, state) => ChatPage()),
        ]),
    GoRoute(
        path: '/report',
        builder: (context, state) => ReportPage()),
    GoRoute(
        path: '/my',
        builder: (context, state) => MyPage(),
        routes: [
          GoRoute(
            path: 'info',
            builder: (context, state) => InfoPage(),
          )
        ]),
    GoRoute(
        path: '/BreathingSolutionPage',
        builder: (context, state) => BreathingSolutionPage(),
        routes: [
          GoRoute(
            path: '/SolutionPage',
            builder: (context, state) => SolutionPage(),
          ),
        ]),
  ],
);
