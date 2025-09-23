import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SolutionPage extends StatefulWidget {
  const SolutionPage({super.key});

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  late final YoutubePlayerController _controller;

  bool _showControls = false; // 오버레이 표시 여부
  bool _isMuted = false; // 음소거 상태

  @override
  void initState() {
    super.initState();

    // ✅ 가로 고정 + 몰입형 UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = YoutubePlayerController(
      initialVideoId: 'IHt4kgF-Ytk', // 원하는 영상 ID
      flags: const YoutubePlayerFlags(
        autoPlay: true, // 페이지 진입 시 자동 재생
        hideControls: true, // 기본 컨트롤 숨김
        disableDragSeek: true, // 드래그 시킹 비활성화(원하면 false)
        enableCaption: false,
        mute: true, // 자동재생 정책 회피하려면 true로 시작 후 첫 탭에서 unMute()
        startAt: 498,
        endAt: 618,
      ),
    );
    _isMuted = true; // ← 플래그와 맞추기

    // 플레이어 상태 리스너(음소거 아이콘 동기화 등 필요시)
    // _controller.addListener(() {
    //   final mutedNow = _controller.value.isMuted;
    //   if (mutedNow != _isMuted) {
    //     setState(() => _isMuted = mutedNow);
    //   }
    // });
  }

////
  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const ar = 16 / 9;

    // 📐 화면을 좌우까지 '덮도록' 필요한 확대 배수 (BoxFit.cover 수동 구현)
    final widthAtScreenHeight = size.height * ar; // 세로 꽉 채웠을 때의 가로폭
    final coverScale = size.width / widthAtScreenHeight; // 좌우 남지 않게 만드는 배수
    const extraZoom = 1.0; // 더 크게 자르고 싶으면 1.05~1.2
    final zoom = coverScale * extraZoom;

    return Scaffold(
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
                    child: const AspectRatio(
                      aspectRatio: ar, // 플레이어 캔버스 비율 유지
                      child: _InnerPlayer(), // 실제 플레이어
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ✋ 탭으로 오버레이 표시/숨김 토글
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showControls = !_showControls),
              child: const SizedBox(),
            ),
          ),

          // 🎛️ 커스텀 오버레이
          if (_showControls)
            Positioned.fill(
              child: Stack(
                children: [
                  // 닫기(X)
                  Positioned(
                    right: 16,
                    top: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),

                  // 음소거 토글
                  Positioned(
                    left: 16,
                    top: 16,
                    child: IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        if (_isMuted) {
                          _controller.unMute();
                        } else {
                          _controller.mute();
                        }
                        _isMuted = !_isMuted; // 로컬 상태 토글
                        setState(() {});
                      },
                    ),
                  ),

                  // ▶️/⏸ 중앙 플레이/일시정지
                  Center(
                    child: IconButton(
                      iconSize: 64,
                      color: Colors.white,
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
  const _InnerPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SolutionPageState>()!;
    return YoutubePlayer(
      controller: state._controller,
      showVideoProgressIndicator: false,
      // progressColors: ProgressBarColors(...), // 필요시
      // onReady: () {},
    );
  }
}
