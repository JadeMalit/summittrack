import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBackground extends StatefulWidget {
  const VideoBackground({
    super.key,
    required this.videoAssetPath,
    this.fallbackImageAssetPath,
    required this.child,
    this.overlayColor = const Color(0x73000000),
    this.backgroundColor = fallbackBackgroundColor,
  });

  static const Color fallbackBackgroundColor = Color(0xFF07140C);
  static final Map<String, VideoPlayerController> _preloadedControllers = {};
  static final Map<String, Future<void>> _preloadFutures = {};

  final String videoAssetPath;
  final String? fallbackImageAssetPath;
  final Widget child;
  final Color overlayColor;
  final Color backgroundColor;

  static Future<void> preload(String videoAssetPath) {
    if (_preloadedControllers.containsKey(videoAssetPath)) {
      return Future<void>.value();
    }

    return _preloadFutures[videoAssetPath] ??= _preloadVideo(videoAssetPath);
  }

  static Future<void> _preloadVideo(String videoAssetPath) async {
    final controller = _createController(videoAssetPath);

    try {
      await _prepareController(controller, shouldPlay: false);
      _preloadedControllers[videoAssetPath] = controller;
    } catch (_) {
      await controller.dispose();
    } finally {
      _preloadFutures.remove(videoAssetPath);
    }
  }

  static VideoPlayerController _createController(String videoAssetPath) {
    return VideoPlayerController.asset(
      videoAssetPath,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
  }

  static Future<void> _prepareController(
    VideoPlayerController controller, {
    required bool shouldPlay,
  }) async {
    await controller.initialize();
    await controller.setVolume(0);
    await controller.setLooping(true);

    if (shouldPlay) {
      await controller.play();
    }
  }

  static VideoPlayerController? _takePreloadedController(
    String videoAssetPath,
  ) {
    return _preloadedControllers.remove(videoAssetPath);
  }

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
    final preloadedController = VideoBackground._takePreloadedController(
      widget.videoAssetPath,
    );

    if (preloadedController != null) {
      _startReadyController(preloadedController);
      return;
    }

    final preloadFuture =
        VideoBackground._preloadFutures[widget.videoAssetPath];
    if (preloadFuture != null) {
      await preloadFuture;

      if (!mounted) return;

      final finishedPreloadController =
          VideoBackground._takePreloadedController(widget.videoAssetPath);

      if (finishedPreloadController != null) {
        _startReadyController(finishedPreloadController, notify: true);
        return;
      }
    }

    final controller = VideoBackground._createController(widget.videoAssetPath);
    _controller = controller;

    try {
      await VideoBackground._prepareController(controller, shouldPlay: true);

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

  void _startReadyController(
    VideoPlayerController controller, {
    bool notify = false,
  }) {
    if (notify) {
      setState(() {
        _controller = controller;
        _isVideoReady = true;
        _videoFailed = false;
      });
    } else {
      _controller = controller;
      _isVideoReady = true;
      _videoFailed = false;
    }

    unawaited(controller.play());
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
        Positioned.fill(child: ColoredBox(color: widget.backgroundColor)),
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
