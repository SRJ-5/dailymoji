import 'package:flutter/material.dart';

/// 커스텀 애니메이션을 제공하는 Page
class CustomAnimatedPage<T> extends Page<T> {
  final Widget child;
  final Duration duration;

  const CustomAnimatedPage({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 500), // 500ms로 사라짐
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 즉시 사라지는 애니메이션
        // 진입: 페이드 인
        // 퇴장: 즉시 사라짐 (애니메이션 없음)
        const curve = Curves.easeInOut;

        var fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var fadeAnimation = animation.drive(fadeTween);

        return FadeTransition(
          opacity: fadeAnimation,
          child: child,
        );
      },
    );
  }
}
