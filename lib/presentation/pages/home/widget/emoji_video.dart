import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class LoopVideo extends StatefulWidget {
  final String assetPath; // ex) 'assets/emoji_videos/angry.mp4'
  final double width;
  final double height;
  final BoxFit fit;

  const LoopVideo({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
  });

  @override
  State<LoopVideo> createState() => _LoopVideoState();
}

class _LoopVideoState extends State<LoopVideo> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  // ✅ 컨트롤러 생성 로직 분리 (재생성/업데이트 시 재사용)
  Future<void> _initController() async {
    _controller = VideoPlayerController.asset(
      widget.assetPath,
      // ✅ 여러 플레이어가 동시에 재생되도록 오디오 포커스 공유
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )
      ..setLooping(true)
      ..setVolume(0.0); // ✅ 항상 무음

    await _controller.initialize();
    if (!mounted) return;
    setState(() => _initialized = true);

    // 화면에 보였던 상태라면 초기화 직후 재생
    if (_visible) _controller.play();
  }

  // ✅ assetPath가 변경되면 컨트롤러를 재생성
  @override
  void didUpdateWidget(covariant LoopVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _initialized = false;
      // 기존 컨트롤러 정리 후 새로 초기화
      _controller.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    if (_initialized && !_controller.value.hasError) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key('video-${widget.assetPath}'),
      onVisibilityChanged: (info) {
        final nowVisible = info.visibleFraction > 0.2; // ✅ 보이면 재생, 안 보이면 일시정지
        _visible = nowVisible;
        if (_initialized && mounted && !_controller.value.hasError) {
          try {
            nowVisible ? _controller.play() : _controller.pause();
          } catch (e) {
            // VideoPlayerController가 dispose된 경우 무시
            print('VideoPlayer error: $e');
          }
        }
      },
      child: _initialized && _controller.value.isInitialized
          ? SizedBox(
              width: widget.width,
              height: widget.height,
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : SizedBox(
              width: widget.width,
              height: widget.height,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
    );
  }
}
