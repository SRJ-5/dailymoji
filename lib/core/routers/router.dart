import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:dailymoji/presentation/pages/my/my_page.dart';
import 'package:dailymoji/presentation/pages/report/report_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => ChatPage()),
    GoRoute(path: '/', builder: (context, state) => ReportPage()),
    // GoRoute(
    //   path: '/next',
    //   // builder: (context, state) => ,
    // ),
  ],
);
