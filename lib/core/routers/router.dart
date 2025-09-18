import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:dailymoji/presentation/pages/chat/chat_page.dart'; // 추가
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final navigatorkey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/chat', // ← 바로 채팅화면 띄우려면 이렇게
  navigatorKey: navigatorkey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => LoginPage()),
    GoRoute(path: '/chat', builder: (context, state) => const ChatPage()), // 추가
  ],
);
