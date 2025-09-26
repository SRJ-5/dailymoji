import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

//백엔드의 context 정보를 임시로 Dart 맵에 만듭니다. ⭐⭐
// 이 페이지에서만 사용할 임시 데이터입니다.
const Map<String, String> solutionContexts = {
  "neg_low_beach_01": "바닷가",
  "neg_low_turtle_01": "바닷속",
  "neg_low_snow_01": "설산",
  "neg_high_cityview_01": "도시 야경",
  "neg_high_campfire_01": "모닥불",
  "neg_high_heartbeat_01": "고요한 물속",
  "adhd_high_space_01": "우주 공간",
  "adhd_high_pomodoro_01": "책상 앞",
  "adhd_high_training_01": "훈련 공간",
  "sleep_forest_01": "밤의 숲속",
  "sleep_onsen_01": "온천",
  "sleep_plane_01": "비행기 안",
  "positive_forest_01": "햇살 가득한 숲",
  "positive_beach_01": "푸른 해변",
  "positive_cafe_01": "재즈 카페",
};

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
  // bool _showFinalHint = false;
  bool _showFinalHint = true; // 개발용으로 일단 true!!!

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  // RIN: 마지막 멘트 컨텍스트 추가
  late final List<Map<String, dynamic>> _steps;

  @override
  void initState() {
    super.initState();
//API 호출 없이, 위에서 만든 임시 맵에서 context를 바로 가져오기
    final contextKey = solutionContexts[widget.solutionId] ?? '그곳';

    _steps = [
      {"text": "코로 4초동안\n숨을 들이마시고", "duration": 4},
      {"text": "7초간 숨을\n머금은 뒤", "duration": 7},
      {"text": "8초간 천천히\n내쉬어 봐!", "duration": 8},
      {
        "text": "지금 배운 호흡법을\n$contextKey에 가서도 해보면\n도움이 될거야!",
        "duration": null,
      },
    ];

    // 깜빡임 애니메이션 컨트롤러
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    ); //..repeat(reverse: true); // 반복 (opacity 1 → 0 → 1)

    _blinkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_blinkController);

// ⭐⭐ 실제 로직을 실행할 때는 아래 주석을 해제하세요. ⭐⭐
    // _showFinalHint = false; // 실제 릴리즈 시에는 false로 시작
    _startSequence(); // 실제 릴리즈 시에는 이 함수 호출

    // ⭐⭐ 개발 테스트를 위해 애니메이션을 즉시 시작합니다. ⭐⭐
    if (_showFinalHint) {
      _blinkController.repeat(reverse: true);
    }
  }

  Future<void> _startSequence() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;

      setState(() {
        _step = i;
        _opacity = 0.0;
        _showFinalHint = false;
      });

      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      // Fade In
      setState(() => _opacity = 1.0);

      final duration = _steps[i]["duration"];

      if (duration != null) {
        // 유지
        await Future.delayed(Duration(seconds: duration));
        setState(() => _showFinalHint = true);

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
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
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
    );
  }
}
