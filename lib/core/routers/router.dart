import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:dailymoji/presentation/pages/my/my_page.dart';
import 'package:dailymoji/presentation/pages/report/report_page.dart';
import 'package:dailymoji/presentation/pages/solution/solution_page.dart';
import 'package:dailymoji/presentation/pages/breathing_solution/breathing_solution_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    navigatorKey: navigatorkey,
    routes: [
      GoRoute(path: '/home', builder: (context, state) => HomePage(), routes: [
        GoRoute(path: '/report', builder: (context, state) => ReportPage()),
        GoRoute(path: '/my', builder: (context, state) => MyPage()),
        GoRoute(path: '/chat', builder: (context, state) => ChatPage()),
      ]),
      GoRoute(
        // 백엔드에서 받는 solutionId를 받도록 설정
        path: '/breathing/:solutionId',
        builder: (context, state) {
          // URL에서 solutionId를 추출
          final solutionId = state.pathParameters['solutionId']!;
          // 페이지에 solutionId를 전달
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
