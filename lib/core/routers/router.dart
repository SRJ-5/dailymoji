import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:dailymoji/presentation/pages/solution/solution_page.dart';
import 'package:dailymoji/presentation/pages/solution_description/solution_description_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => HomePage()),
    GoRoute(
        path: '/SolutionDescription',
        builder: (context, state) => SolutionDescriptionPage(),
        routes: [
          GoRoute(
            path: 'Solution',
            builder: (context, state) => SolutionPage(),
          ),
        ]),
  ],
);
