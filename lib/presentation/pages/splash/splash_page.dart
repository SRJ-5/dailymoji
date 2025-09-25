import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // 페이드아웃 시간 = 1초
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(_controller);

    // 2초 유지 후 → 1초 동안 페이드아웃
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 뒤에 LoginPage
        LoginPage(),

        // 위에 SplashPage 이미지 (페이드아웃)
        FadeTransition(
          opacity: _opacity,
          child: IgnorePointer(
            ignoring: _opacity.value != 0,
            child: Image.asset(
              "assets/images/splash_image.png",
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }
}
