import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(
      path: '/',
      // builder: (context, state) =>
    ),
    GoRoute(
      path: '/next',
      // builder: (context, state) => ,
    ),
  ],
);
