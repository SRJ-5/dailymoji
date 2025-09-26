// lib/core/widgets/portrait_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// 세로 모드를 강제하는 커스텀 페이지 클래스
class PortraitPage extends CustomTransitionPage {
  const PortraitPage({
    required Widget child,
    LocalKey? key,
  }) : super(
          key: key,
          child: child,
          transitionsBuilder: _transitionsBuilder,
        );

  @override
  Route createRoute(BuildContext context) {
    // 이 페이지로 들어올 때마다 세로 모드로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return super.createRoute(context);
  }
}

// 기본 페이지 전환 효과 (Fade)
Widget _transitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
