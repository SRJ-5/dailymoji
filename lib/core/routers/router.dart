import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:dailymoji/presentation/pages/my/my_page.dart';
import 'package:dailymoji/presentation/pages/report/report_page.dart';
import 'package:dailymoji/presentation/pages/solution/solution_page.dart';
import 'package:dailymoji/presentation/pages/breathing_solution/breathing_solution_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/home',
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(path: '/home', builder: (context, state) => ReportPage(), routes: [
      GoRoute(path: '/report', builder: (context, state) => ReportPage()),
      GoRoute(path: '/my', builder: (context, state) => MyPage()),
      GoRoute(path: '/ChatPage', builder: (context, state) => ChatPage()),
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
