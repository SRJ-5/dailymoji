import 'package:dailymoji/presentation/pages/chat/chat_page.dart';
import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:dailymoji/presentation/pages/my/my_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/chat', // ← 바로 채팅화면 띄우려면 이렇게
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => ChatPage()),
    // GoRoute(
    //   path: '/next',
    //   // builder: (context, state) => ,
    // ),
  ],
);
