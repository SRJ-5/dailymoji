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
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        if (_visible) _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key(widget.assetPath),
      onVisibilityChanged: (info) {
        final nowVisible = info.visibleFraction > 0.3;
        if (_initialized) {
          nowVisible ? _controller.play() : _controller.pause();
        }
        _visible = nowVisible;
      },
      child: _initialized
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
