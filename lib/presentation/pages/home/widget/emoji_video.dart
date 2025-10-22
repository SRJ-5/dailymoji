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

class _LoopVideoState extends State<LoopVideo>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController? _controller;
  bool _initialized = false;
  bool _visible = false;
  bool _disposed = false; // ✅ 추가

  @override
  void initState() {
    super.initState();
    _initController();
  }

  // ✅ 컨트롤러 생성 로직 분리 (재생성/업데이트 시 재사용)
  Future<void> _initController() async {
    final c = VideoPlayerController.asset(
      widget.assetPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )
      ..setLooping(true)
      ..setVolume(0.0);

    _controller = c;
    try {
      await c.initialize();
      if (!mounted || _disposed) return;
      setState(() => _initialized = true);
      if (_visible) c.play();
    } catch (_) {
      // 초기화 실패 시 무시(다른 포맷 문제는 아래 2번 참조)
    }
  }

  // ✅ assetPath가 변경되면 컨트롤러를 재생성
  @override
  void didUpdateWidget(covariant LoopVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _initialized = false;
      _controller?.dispose();
      _controller = null;
      _initController();
    }
  }

  @override
  void dispose() {
    _disposed = true; // ✅ 콜백에서 참조 금지
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key('video-${widget.assetPath}'),
      onVisibilityChanged: (info) {
        final nowVisible = info.visibleFraction > 0.2; // ✅ 보이면 재생, 안 보이면 일시정지
        _visible = nowVisible;
        final c = _controller;

        if (_disposed || c == null || !_initialized) return; // ✅ 가드

        if (nowVisible) {
          if (!c.value.isPlaying) c.play();
        } else {
          if (c.value.isPlaying) c.pause();
        }
      },
      child: (_controller != null &&
              _initialized &&
              !_disposed &&
              _controller!.value.isInitialized)
          ? SizedBox(
              width: widget.width,
              height: widget.height,
              child: FittedBox(
                fit: widget.fit,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
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

  @override
  bool get wantKeepAlive => true;
}
