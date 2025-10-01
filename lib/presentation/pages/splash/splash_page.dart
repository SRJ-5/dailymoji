import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // 페이드아웃 시간 = 1초
    );
    _opacity =
        Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    _startAnimation(); // 애니메이션 시작 함수 호출
  }

  /// 스플래시 애니메이션을 시작하는 함수
  /// 한 번만 실행되도록 _hasStartedAnimation 플래그로 제어
  void _startAnimation() {
    // 2초 유지 후 → 1초 동안 페이드아웃 시작
    Future.delayed(Duration(seconds: 2), () {
      // mounted: 위젯이 여전히 트리에 있는지 확인
      // !_controller.isAnimating: 이미 애니메이션 중이 아닌지 확인
      if (mounted && !_controller.isAnimating) {
        _controller.forward(); // 페이드아웃 애니메이션 시작
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Visibility(
              // 애니메이션이 완료되지 않았으면 보이기, 완료되면 완전히 숨기기
              visible: !_controller.isCompleted,
              child: FadeTransition(
                opacity: _opacity,
                child: Image.asset(
                  AppImages.splashImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
