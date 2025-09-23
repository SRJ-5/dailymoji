import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BreathingSolutionPage extends StatefulWidget {
  final String solutionId;

  const BreathingSolutionPage({super.key, required this.solutionId});

  @override
  State<BreathingSolutionPage> createState() => _BreathingSolutionPageState();
}

class _BreathingSolutionPageState extends State<BreathingSolutionPage>
    with SingleTickerProviderStateMixin {
  double _opacity = 0.0;
  int _step = 0;
  bool _showFinalHint = false;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  final List<Map<String, dynamic>> _steps = [
    // 리스트 맵을 이용해서 데이터 한방에 처리
    {"text": "코로 4초동안\n숨을 들이마시고", "duration": 4},
    {"text": "7초간 숨을\n머금은 뒤", "duration": 7},
    {"text": "8초간 천천히\n내쉬어 봐!", "duration": 8},
    {
      "text": "지금 배운 호흡법을\n바다에 가서도 해보면\n도움이 될거야!",
      "duration": null, // 마지막은 사라지지 않음
    },
  ];

  @override
  void initState() {
    super.initState();

    // 깜빡임 애니메이션 컨트롤러
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // 반복 (opacity 1 → 0 → 1)

    _blinkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_blinkController);

    _startSequence();
  }

  Future<void> _startSequence() async {
    for (int i = 0; i < _steps.length; i++) {
      setState(() {
        _step = i;
        _opacity = 0.0;
        _showFinalHint = false;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // Fade In
      setState(() => _opacity = 1.0);

      final duration = _steps[i]["duration"];

      if (duration != null) {
        // 유지
        await Future.delayed(Duration(seconds: duration));

        // Fade Out
        setState(() => _opacity = 0.0);
        await Future.delayed(const Duration(seconds: 1));
      } else {
        // 마지막 단계 → 3초 기다렸다가 안내 문구 표시
        await Future.delayed(const Duration(seconds: 3));
        setState(() => _showFinalHint = true);
        break;
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 빈 공간도 터치 감지
      onTap: () {
        if (_showFinalHint) {
          context.go('/solution/${widget.solutionId}');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 단계별 텍스트
              Positioned(
                top: 150,
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(seconds: 1),
                  child: Text(
                    _steps[_step]["text"],
                    style: const TextStyle(color: Colors.white, fontSize: 35),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // 캐릭터
              const Positioned(
                top: 320,
                child: SizedBox(
                  width: 250,
                  height: 400,
                  child: Image(
                    image: AssetImage("assets/images/cado_00.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // 깜빡이는 안내 문구
              if (_showFinalHint)
                Positioned(
                  bottom: 60,
                  child: FadeTransition(
                    opacity: _blinkAnimation,
                    child: const Text(
                      "탭하여 영상으로 넘어가기",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
