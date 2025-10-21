import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/guide/guide_page.dart';
import 'package:dailymoji/presentation/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _controller;
  late Animation<double> _opacity;
  bool isFirstLaunch = false;
  final connectNetwork = Connectivity();
  late bool hasConnection;

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
  Future<void> _startAnimation() async {
    // 2초 유지 후 → 1초 동안 페이드아웃 시작
    await Future.delayed(Duration(seconds: 2), () {
      // mounted: 위젯이 여전히 트리에 있는지 확인
      // !_controller.isAnimating: 이미 애니메이션 중이 아닌지 확인
      if (mounted && !_controller.isAnimating) {
        _controller.forward(); // 페이드아웃 애니메이션 시작
      }
    });

    // 앱을 처음 들어오는지 확인
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    setState(() {
      isFirstLaunch = firstLaunch;
    });
  }

  // 네트워크 연결 체크
  Future<void> _checkConnention() async {
    final connectivityResult =
        await connectNetwork.checkConnectivity();
    _checkConnention();
    hasConnection = connectivityResult.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  void _goToNetworkErrorPage() {
    context.go('/network_error');
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
        hasConnection == false ? _goToNetworkErrorPage(); : isFirstLaunch == true
            ? GuidePage()
            :
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
