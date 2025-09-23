import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:dailymoji/presentation/pages/my/my_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part1_page.dart';
import 'package:dailymoji/presentation/pages/onboarding/onboarding_part2_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorkey,
  // redirect: (context, state) {
  //   final user = Supabase.instance.client.auth.currentUser;
  //   print(user);
  //   if (user != null && state.uri.path == '/') {
  //     return '/onboarding1';
  //   }
  //   return null;
  // },
  routes: [
    GoRoute(path: '/', builder: (context, state) => LoginPage()),
    GoRoute(
        path: '/onboarding1',
        builder: (context, state) => OnboardingPart1Page()),
    GoRoute(
      path: '/onboarding2',
      builder: (context, state) => OnboardingPart2Page(),
    )
  ],
);
