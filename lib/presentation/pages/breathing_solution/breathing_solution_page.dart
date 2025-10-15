import 'dart:async';
import 'dart:math';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/fonts.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/breathing_solution/solution_context_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class BreathingSolutionPage extends ConsumerStatefulWidget {
  final String solutionId;
  final String? sessionId;
  final bool isReview;

  const BreathingSolutionPage(
      {super.key,
      required this.solutionId,
      this.sessionId,
      this.isReview = false});

  @override
  ConsumerState<BreathingSolutionPage> createState() =>
      _BreathingSolutionPageState();
}

class _BreathingSolutionPageState extends ConsumerState<BreathingSolutionPage>
    with TickerProviderStateMixin {
  double _opacity = 0.0;
  int _step = 0;
  int _timerSeconds = 0;

  bool _showFinalHint = false;

  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

// RIN: 타이머 추가
  late AnimationController _timerController;
  Timer? _secondTimer; // 1초마다 숫자를 업데이트할 Timer 변수 추가

  // RIN: 마지막 멘트 컨텍스트 추가
  List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();

    // 1. 기본값으로 즉시 초기화 (late error 방지)
    _steps = [
      {
        "title": null,
        "text": "함께 차분해지는\n호흡 연습을 해볼까요?",
        "font": AppFontStyles.heading2,
        "duration": 2,
      },
      {
        "title": "Step 1.",
        "text": "코로 4초동안\n숨을 들이마시고",
        "font": AppFontStyles.heading3,
        "duration": 4,
      },
      {
        "title": "Step 2.",
        "text": "7초간 숨을\n머금은 뒤",
        "font": AppFontStyles.heading3,
        "duration": 7,
      },
      {
        "title": "Step 3.",
        "text": "8초간 천천히\n내쉬어 봐!",
        "font": AppFontStyles.heading3,
        "duration": 8,
      },
      {
        "title": null,
        "text": "잘 했어요!\n이제 일상에 가서도\n호흡을 이어가 보세요",
        "font": AppFontStyles.heading2,
        "duration": 2,
      },
    ];

    // 2. 비동기로 실제 데이터 가져와서 업데이트
    _loadSolutionContext();

    // 깜빡임 애니메이션 컨트롤러
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // 반복 (opacity 1 → 0 → 1)

    _blinkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_blinkController);

    // RIN: 타이머 추가
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // duration은 나중에 동적으로 변경됩니다.
    );

    _timerController.addListener(() {
      if (!mounted) return;
      final duration = _steps[_step]["duration"];
      if (duration != null) {
        // 애니메이션 진행률(0.0~1.0)에 따라 초를 계산 (ceil로 올림처리하여 1부터 시작)
        final newSeconds = (_timerController.value * duration).ceil();
        if (_timerSeconds != newSeconds) {
          setState(() {
            _timerSeconds = newSeconds;
          });
        }
      }
    });

    _startSequence();
  }

  // 솔루션 컨텍스트를 비동기로 가져와서 _steps를 업데이트
  Future<void> _loadSolutionContext() async {
    try {
      final solutionContext = await ref
          .read(solutionContextViewModelProvider.notifier)
          .getSolutionContext(widget.solutionId);

      if (mounted) {
        setState(() {
          // _steps의 마지막 항목을 실제 데이터로 업데이트
          _steps[4]["text"] = "잘 했어요!\n이제 $solutionContext에 가서도\n호흡을 이어가 보세요";
        });
      }
    } catch (e) {
      print("Error loading solution context: $e");
      // 에러 시 기본값("일상") 유지
    }
  }

// RIN: _startSequence 함수 로직 전체 수정
  Future<void> _startSequence() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;

      // 1. 현재 스텝 정보 설정 및 Fade In
      setState(() {
        _step = i;
        _opacity = 1.0;
        _showFinalHint = false; // 각 스텝 시작 시에는 항상 힌트 숨김
        _timerSeconds = 0;
      });
      _secondTimer?.cancel(); // 이전 타이머가 있다면 취소

      final duration = _steps[i]["duration"];

      // 2. Duration이 있는 스텝 (중간 단계들)
      if (duration != null) {
        // 타이머 애니메이션 시작
        _timerController.duration = Duration(seconds: duration);
        _timerController.forward(from: 0.0);

        // 해당 스텝의 duration 만큼 대기
        await Future.delayed(Duration(seconds: duration));

        // Fade Out (마지막 스텝 전까지만)
        if (i < _steps.length - 1) {
          if (!mounted) return;
          setState(() => _opacity = 0.0);
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    // 3. 모든 스텝이 끝난 후 (마지막 단계)
    if (mounted) {
      setState(() {
        _showFinalHint = true; // 최종 힌트 표시
      });
      _blinkController.repeat(reverse: true); // 깜빡임 시작
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _timerController.dispose(); // RIN: 타이머 추가
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCharacterNum =
        ref.read(userViewModelProvider).userProfile!.characterNum;
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // 빈 공간도 터치 감지
      onTap: () {
        if (_showFinalHint) {
          context.pushReplacement(
              '/solution/${widget.solutionId}?sessionId=${widget.sessionId}&isReview=${widget.isReview}');
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
              top: 167.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 300),
                  // RIN: 문구 수정
                  child: Column(
                    children: [
                      if (_steps[_step]["title"] != null)
                        AppText(
                          _steps[_step]["title"],
                          style: AppFontStyles.heading2
                              .copyWith(color: AppColors.grey100),
                          textAlign: TextAlign.center,
                        ),
                      AppText(
                        _steps[_step]["text"],
                        style: (_steps[_step]["font"] as TextStyle)
                            .copyWith(color: AppColors.grey100),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 캐릭터
            Positioned(
              top: 245.h,
              child: SizedBox(
                width: 240.w,
                height: 360.h,
                child: Image(
                  image: AssetImage(
                      AppImages.characterListProfile[selectedCharacterNum!]),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            //RIN: 타이머 (Step 1~3 동안만 표시)
            Positioned(
              top: 625.h,
              child: AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  bool isTimerHidden = _step == 0 ||
                      _step >= _steps.length - 1 ||
                      _opacity == 0.0;
                  if (isTimerHidden) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    painter: TimerPainter(
                      progress: _timerController.value,
                      seconds: _timerSeconds,
                    ),
                    size: Size(60.w, 60.w),
                  );
                },
              ),
            ),

            // '건너뛰기' 텍스트 버튼 추가
            if (!_showFinalHint && _step > 0 && _step < _steps.length - 1)
              Positioned(
                top: 700.h, // 타이머보다 살짝 아래 위치
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onTap: () {
                      // 즉시 다음 라우트로 이동
                      context.pushReplacement(
                        '/solution/${widget.solutionId}?sessionId=${widget.sessionId}&isReview=${widget.isReview}',
                      );
                    },
                    child: Text(
                      "건너뛰기",
                      style: AppFontStyles.bodyMedium16.copyWith(
                        color: AppColors.grey400,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.grey400, // ✅ 밑줄 색을 강제로 지정
                      ),
                    ),
                  ),
                ),
              ),

            // 깜빡이는 안내 문구
            if (_showFinalHint)
              Positioned(
                top: 625.h,
                child: FadeTransition(
                  opacity: _blinkAnimation,
                  child: AppText(
                    "화면을 탭해서 다음으로 넘어가세요",
                    style: AppFontStyles.bodyMedium18
                        .copyWith(color: AppColors.grey400),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// RIN: 타이머 ui 클래스
class TimerPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0
  final int seconds;

  TimerPainter({required this.progress, required this.seconds});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 배경 원 (채우기: white 35%)
    final fillPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // 배경 원(테두리: Gray 100, 두께 4)
    final backgroundPaint = Paint()
      ..color = AppColors.grey100
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 진행 상태 원호(Orange 400, 두께 4, 끝 둥글게)
    final progressPaint = Paint()
      ..color = AppColors.orange400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // 원호 그리기 (시작점: -90도, 즉 12시 방향)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2, // 12시 방향에서 시작
      progress * 2 * pi, // 진행도에 따라 원호를 채움
      false,
      progressPaint,
    );

    // 가운데 숫자 (heading2, white)
    if (seconds > 0) {
      final textPainter = TextPainter(
        text: TextSpan(
            text: '$seconds',
            style: AppFontStyles.heading2.copyWith(color: AppColors.white)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2 + 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seconds != seconds;
  }
}
