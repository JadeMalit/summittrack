import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  const VideoBackground({
    super.key,
    required this.videoAssetPath,
    this.fallbackImageAssetPath,
    required this.child,
    this.overlayColor = const Color(0x73000000),
  });

  final String videoAssetPath;
  final String? fallbackImageAssetPath;
  final Widget child;
  final Color overlayColor;

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isVideoReady = false;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.asset(
      widget.videoAssetPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _isVideoReady = true;
        _videoFailed = false;
      });
    } catch (_) {
      await controller.dispose();

      if (!mounted) return;

      setState(() {
        if (identical(_controller, controller)) {
          _controller = null;
        }
        _isVideoReady = false;
        _videoFailed = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !_isVideoReady) return;

    if (state == AppLifecycleState.resumed) {
      controller.play();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.fallbackImageAssetPath != null)
          Positioned.fill(
            child: Image.asset(
              widget.fallbackImageAssetPath!,
              fit: BoxFit.cover,
            ),
          ),
        if (controller != null && !_videoFailed)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isVideoReady ? 1 : 0,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: controller.value.isInitialized
                        ? controller.value.size.width
                        : 1,
                    height: controller.value.isInitialized
                        ? controller.value.size.height
                        : 1,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(child: ColoredBox(color: widget.overlayColor)),
        Positioned.fill(child: widget.child),
      ],
    );
  }
}
