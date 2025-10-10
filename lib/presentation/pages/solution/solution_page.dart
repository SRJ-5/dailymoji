import 'dart:math' as math;

import 'package:dailymoji/core/providers.dart';
import 'package:dailymoji/core/styles/images.dart';
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

  const SolutionPage(
      {super.key,
      required this.solutionId,
      this.sessionId,
      this.isReview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solutionAsync = ref.watch(solutionProvider(solutionId));

    return solutionAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.black,
        body: Center(
          child: AppText("솔루션을 불러오는 데 실패했습니다: $err",
              style: const TextStyle(color: AppColors.white)),
        ),
      ),
      data: (solution) {
        // 데이터 로딩 성공 시, 비디오 플레이어 UI를 렌더링
        return _PlayerView(
          solutionId: solutionId,
          sessionId: sessionId,
          solution: solution,
          isReview: isReview,
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

  const _PlayerView({
    required this.solutionId,
    this.sessionId,
    required this.solution,
    required this.isReview,
  });

  @override
  ConsumerState<_PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends ConsumerState<_PlayerView> {
  late final YoutubePlayerController _controller;
  bool _showControls = false;
  bool _isMuted = true;
  bool _isNavigating = false;
  bool _showCharacter = false;
  bool _characterTimerStarted = false;

  String? _exitReason;

  @override
  void initState() {
    super.initState();
    // 가로 고정 + 몰입형 UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Provider로부터 받은 solution 데이터로 컨트롤러 초기화
    _controller = YoutubePlayerController(
      initialVideoId: widget.solution.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true, // 페이지 진입 시 자동 재생
        hideControls: true, // 기본 컨트롤 숨김
        disableDragSeek: true, // 드래그 시킹 비활성화(원하면 false)
        enableCaption: false,
        mute: true, // 자동재생 정책 회피하려면 true로 시작 후 첫 탭에서 unMute()
        startAt: widget.solution.startAt,
        endAt: widget.solution.endAt,
      ),
    );
    // _isMuted = true; // ← 플래그와 맞추기
    _controller.addListener(_playerListener);

// RIN: 0.1초 후에 음소거를 해제로직 추가
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _controller.unMute();
        setState(() {
          _isMuted = false;
        });
      }
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
    // 플레이어 컨트롤 개선: 컨트롤러 값(재생/일시정지 상태 등)이 변경될 때마다 UI를 갱신
    if (mounted) {
      setState(() {});
    }

    // 영상이 실제 재생될 때 캐릭터 타이머 시작
    if (_controller.value.playerState == PlayerState.playing &&
        !_characterTimerStarted) {
      _characterTimerStarted = true;
      setState(() => _showCharacter = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showCharacter = false);
      });
    }

    if (_controller.value.playerState == PlayerState.ended) {
      // "나가는 이유"를 'video_ended'로 확정하고
      _exitReason = 'video_ended';
      // 네비게이션 시작을 요청합니다.
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
      };
    } else {
      debugPrint("RIN: This is a review. Skipping follow-up message.");
    }

    // Go back to using `context.go` which is more stable.
    context.go('/home/chat');
  }

  @override
  void dispose() {
    _controller.removeListener(_playerListener);
    _controller.dispose();
    // 돌려놓은 화면 UI 다시 원상복구
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              duration: const Duration(seconds: 1), // 1초 동안 서서히 사라짐
              curve: Curves.easeOut,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 캐릭터 이미지
                  Transform(
                    alignment: Alignment.center, // 중심축 기준으로 반전
                    transform: Matrix4.rotationY(math.pi), // 좌우 반전
                    child: Image.asset(
                      AppImages.cadoWalk,
                      height: 180.h,
                    ),
                  ),
                  // 말풍선
                  const SolutionBubble(
                    text: '제가 옆에서 함께할게요.\n영상을 보면서 호흡법을 유지해보세요!',
                  ),
                ],
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
                        _controller.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
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
