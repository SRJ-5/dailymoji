import 'package:dailymoji/presentation/pages/home/dailymoji_home_page.dart';
import 'package:dailymoji/presentation/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => DailyMojiHomePage())
  ],
);
