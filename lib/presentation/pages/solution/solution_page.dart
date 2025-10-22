import 'dart:async';
import 'dart:math' as math;

import 'package:dailymoji/core/constants/app_text_strings.dart';
import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/styles/images.dart';
import 'package:dailymoji/presentation/pages/onboarding/view_model/user_view_model.dart';
import 'package:dailymoji/presentation/pages/solution/widget/solution_bubble.dart';
import 'package:dailymoji/presentation/widgets/app_text.dart';
import 'package:dailymoji/core/styles/colors.dart';
import 'package:dailymoji/domain/entities/solution.dart';
import 'package:dailymoji/presentation/pages/chat/chat_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SolutionPage extends ConsumerWidget {
  final String solutionId;
  final String? sessionId;
  final bool isReview;
  final String solutionType;

  const SolutionPage({
    super.key,
    required this.solutionId,
    this.sessionId,
    this.isReview = false,
    this.solutionType = 'video',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCharacterNum = ref.read(userViewModelProvider).userProfile!.characterNum;
    final solutionAsync = ref.watch(solutionProvider(solutionId));

    return solutionAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: AppText('${AppTextStrings.solutionLoadFailed.split('%s')[0]}$err', style: const TextStyle(color: AppColors.white)),
        ),
      ),
      data: (solution) {
        // 데이터 로딩 성공 시, 비디오 플레이어 UI를 렌더링
        if (solution.videoId == null) {
          return const Scaffold(
            backgroundColor: AppColors.black,
            body: Center(
              child: AppText("재생할 수 없는 마음 관리 팁 유형입니다.", style: TextStyle(color: AppColors.white)),
            ),
          );
        }
        return _PlayerView(
          solutionId: solutionId,
          sessionId: sessionId,
          solution: solution,
          isReview: isReview,
          solutionType: solutionType,
        );
      },
    );
  }
}

// 실제 플레이어 UI를 담당하는 위젯
class _PlayerView extends ConsumerStatefulWidget {
  final String solutionId;
  final String? sessionId;
  final Solution solution;
  final bool isReview;
  final String solutionType;

  const _PlayerView({
    required this.solutionId,
    this.sessionId,
    required this.solution,
    required this.isReview,
    required this.solutionType,
  });

  @override
  ConsumerState<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<_PlayerView> {
  late final YoutubePlayerController _controller;

  bool _showControls = false;
  bool _isMuted = true;
  bool _isNavigating = false;

  // 캐릭터/말풍선 제어
  bool _showCharacter = false;
  bool _characterTimerStarted = false; // 최초 훅 3초용
  bool _secondPromptShown = false; // 2분 후 트리거는 1회만
  String _bubbleText = '제가 옆에서 함께할게요.\n2분 동안 영상에 집중해 봐요!\n원하시면 언제든 나갈 수 있어요.';

  // 누적 재생시간 측정용
  Duration _accumulatedPlay = Duration.zero;
  Duration? _lastPosition;
  Timer? _playTimer;

  String? _exitReason;

  @override
  void initState() {
    super.initState();
    // 가로 고정 + 몰입형 UI 유지
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = YoutubePlayerController(
      initialVideoId: widget.solution.videoId!,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        hideControls: true,
        disableDragSeek: true,
        enableCaption: false,
        mute: true,
      ),
    )..addListener(_playerListener);

    // 자동 재생 정책 회피 후 곧바로 unmute
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _controller.unMute();
      setState(() => _isMuted = false);
    });

    // ✅ 누적 재생 타이머 (실제 재생된 시간만 합산)
    _playTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      final value = _controller.value;

      // playing 상태일 때만 측정 (버퍼/일시정지는 제외)
      if (value.playerState == PlayerState.playing) {
        final current = value.position;
        if (_lastPosition != null && current > _lastPosition!) {
          _accumulatedPlay += current - _lastPosition!;
        }
        _lastPosition = current;

        // 2분(=120초) 경과 시 1회만 말풍선 재등장
        if (!_secondPromptShown && _accumulatedPlay.inSeconds >= 120) {
          _secondPromptShown = true;
          _triggerSecondPrompt();
        }
      } else {
        // playing이 아니면 포지션만 갱신 (seek 대비)
        _lastPosition = value.position;
      }
    });
  }

// “2분 후 말풍선” 트리거 함수
  void _triggerSecondPrompt() {
    if (!mounted) return;
    setState(() {
      _bubbleText = '2분이 지났어요!\n괜찮다면 깊게 호흡하며\n영상에 조금 더 머물러보세요.';
      _showCharacter = true;
    });

    // 4~5초 후 자동 숨김
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showCharacter = false);
    });
  }

// // 영상 종료 시 채팅 페이지로 돌아가는 리스너
//     _controller.addListener(() {
//       if (_isNavigating) return; // 이미 이동 중이면 무시

//       if (_controller.value.playerState == PlayerState.ended) {
//         debugPrint("RIN: YouTube video ended. Navigating to chat page.");
//         _navigateToChatPage(reason: 'video_ended'); // 영상이 끝나면 채팅 페이지로 이동
//       }
//       // 플레이어 상태 리스너(음소거 상태를 동기화)
//       // final mutedNow = _controller.value.isMuted;
//       // if (mutedNow != _isMuted) {
//       //   setState(() => _isMuted = mutedNow);
//       // }
//     });
//   }

  void _playerListener() {
    if (mounted) setState(() {}); // 컨트롤 아이콘 갱신 등

    // 최초 재생 시작 시, 첫 훅 (3초 표시)
    if (_controller.value.playerState == PlayerState.playing && !_characterTimerStarted) {
      _characterTimerStarted = true;
      setState(() {
        _bubbleText = '제가 옆에서 함께할게요.\n영상을 보면서 호흡법을 유지해보세요!';
        _showCharacter = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showCharacter = false);
      });
    }

    if (_controller.value.playerState == PlayerState.ended) {
      _exitReason = 'video_ended';
      _startExitSequence();
    }
  }

//모든 네비게이션 로직을 처리하는 유일한 함수
  void _startExitSequence() {
    // 이미 나가는 중이면 아무것도 하지 않습니다.
    if (_isNavigating) return;
    _isNavigating = true;

    if (!widget.isReview) {
      // `_exitReason`이 설정되지 않았다면 비정상적인 경우이므로, 안전하게 'user_closed'로 처리합니다.
      final reason = _exitReason ?? 'user_closed';
      debugPrint("RIN: Setting result and navigating with reason: $reason");

      ref.read(solutionResultProvider.notifier).state = {
        'reason': reason,
        'solutionId': widget.solutionId,
        'sessionId': widget.sessionId,
        'solution_type': widget.solutionType,
      };
    } else {
      debugPrint("RIN: This is a review. Skipping follow-up message.");
    }

    // Go back to using `context.go` which is more stable.
    // context.go('/home/chat');
    context.pop();
  }

  @override
  void dispose() {
    _controller.removeListener(_playerListener);
    _controller.dispose();
    _playTimer?.cancel(); // ✅ 타이머 해제

    // 세로 원복
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCharacterNum = ref.read(userViewModelProvider).userProfile!.characterNum;
    final size = MediaQuery.of(context).size;
    const ar = 16 / 9;

    // 화면을 좌우까지 '덮도록' 필요한 확대 배수 (BoxFit.cover 수동 구현)
    final widthAtScreenHeight = size.height * ar; // 세로 꽉 채웠을 때의 가로폭
    final coverScale = size.width / widthAtScreenHeight; // 좌우 남지 않게 만드는 배수
    const extraZoom = 1; // 더 크게 자르고 싶으면 1.05~1.2
    final zoom = coverScale * extraZoom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // 🎥 유튜브 플레이어(터치 무력화 + 화면 꽉 채우기)
          Positioned.fill(
            child: IgnorePointer(
              // 유튜브 기본 터치/제스처 차단
              ignoring: true,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.scale(
                    alignment: Alignment.center,
                    scale: zoom, // ✅ 통째 확대(가로 꽉, 위아래 크롭)
                    child: AspectRatio(
                      aspectRatio: ar, // 플레이어 캔버스 비율 유지
                      // child: _InnerPlayer(), // 실제 플레이어
                      child: _InnerPlayer(
                        controller: _controller,
                        onReady: () {
                          // 플레이어 준비 완료 후 자동으로 음소거 해제
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (mounted) {
                              _controller.unMute();
                              setState(() {
                                _isMuted = false;
                              });
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 캐릭터 + 말풍선
          Positioned(
            left: 10.w,
            bottom: 19.h,
            child: AnimatedOpacity(
              opacity: _showCharacter ? 1 : 0,
              duration: const Duration(seconds: 1),
              curve: Curves.easeOut,
              child: SafeArea(
                left: true,
                right: false,
                top: false,
                bottom: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      AppImages.characterListWalk[selectedCharacterNum!],
                      height: 180.h,
                    ),
                    SizedBox(width: 10.w),
                    SolutionBubble(text: _bubbleText), // ✅ 대사 바인딩
                  ],
                ),
              ),
            ),
          ),

          // 탭으로 오버레이 표시/숨김 토글 + 첫 터치 시 음소거 해제
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // // 첫 터치 시 음소거 해제 (자동재생 정책 우회)
                // if (_isMuted) {
                //   _controller.unMute();
                //   setState(() {
                //     _isMuted = false;
                //   });
                // }
                setState(() => _showControls = !_showControls);
              },
              child: const SizedBox(),
            ),
          ),

          // 커스텀 오버레이
          if (_showControls)
            Positioned.fill(
              child: Stack(
                children: [
                  // 닫기(X)
                  Positioned(
                    right: 16.w,
                    top: 16.h,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: 32.r,
                      ),
                      // onPressed: () => Navigator.of(context).pop(),
                      //RIN: X 버튼을 누르면 'user_closed' 신호를 extra로
                      onPressed: () {
                        _exitReason = 'user_closed';
                        _startExitSequence();
                      },
                    ),
                  ),

                  // 음소거 토글
                  Positioned(
                    left: 16.w,
                    top: 16.h,
                    child: IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: AppColors.white,
                        size: 28.r,
                      ),
                      onPressed: () {
                        if (_isMuted) {
                          _controller.unMute();
                        } else {
                          _controller.mute();
                        }
                        setState(() => _isMuted = !_isMuted);
                      },
                    ),
                  ),

                  // ▶ / ⏸ 중앙 플레이/일시정지
                  Center(
                    child: IconButton(
                      iconSize: 64.r,
                      color: AppColors.white,
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      ),
                      onPressed: () {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                        setState(() {}); // 아이콘 갱신
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// YoutubePlayer 위젯을 분리해 두면 Transform/Clip 위에 올리기 편함
class _InnerPlayer extends StatelessWidget {
  final YoutubePlayerController controller;
  final VoidCallback? onReady;

  const _InnerPlayer({required this.controller, this.onReady});

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: false,
      onReady: onReady, // 플레이어 준비 완료 콜백
    );
  }
}
