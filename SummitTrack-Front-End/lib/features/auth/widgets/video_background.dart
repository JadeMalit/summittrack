import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:video_player/video_player.dart';

import '../../../core/routing/app_route_observer.dart';

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
  static final Map<String, Future<int>> _assetVerificationFutures = {};

  final String videoAssetPath;
  final String? fallbackImageAssetPath;
  final Widget child;
  final Color overlayColor;
  final Color backgroundColor;

  static Future<void> preload(String videoAssetPath) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Future<void>.value();
    }

    if (_preloadedControllers.containsKey(videoAssetPath)) {
      return Future<void>.value();
    }

    return _preloadFutures[videoAssetPath] ??= _preloadVideo(videoAssetPath);
  }

  static Future<void> _preloadVideo(String videoAssetPath) async {
    final controller = _createController(videoAssetPath);

    try {
      await _verifyAssetExists(videoAssetPath);
      await _prepareController(controller, shouldPlay: false);
      _preloadedControllers[videoAssetPath] = controller;
    } catch (error, stackTrace) {
      _logVideoError(videoAssetPath, 'preload', error, stackTrace);
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

  static Future<int> _verifyAssetExists(String videoAssetPath) {
    return _assetVerificationFutures[videoAssetPath] ??=
        _loadAssetForVerification(videoAssetPath);
  }

  static Future<int> _loadAssetForVerification(String videoAssetPath) async {
    try {
      final data = await rootBundle.load(videoAssetPath);
      debugPrint(
        'VideoBackground asset "$videoAssetPath" found '
        '(${data.lengthInBytes} bytes).',
      );
      return data.lengthInBytes;
    } catch (_) {
      _assetVerificationFutures.remove(videoAssetPath);
      rethrow;
    }
  }

  static Future<void> _prepareController(
    VideoPlayerController controller, {
    required bool shouldPlay,
  }) async {
    await controller.initialize();
    _throwIfControllerHasError(controller);
    await controller.setVolume(0);
    await controller.setLooping(true);

    if (shouldPlay) {
      await controller.play();
      _throwIfControllerHasError(controller);
    }
  }

  static void _throwIfControllerHasError(VideoPlayerController controller) {
    if (!controller.value.hasError) return;

    throw StateError(
      controller.value.errorDescription ?? 'Unknown video player error.',
    );
  }

  static void _logVideoError(
    String videoAssetPath,
    String phase,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    debugPrint('VideoBackground error while $phase "$videoAssetPath": $error');
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'summittrack video background',
        context: ErrorDescription('while $phase video asset "$videoAssetPath"'),
      ),
    );
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
    with WidgetsBindingObserver, RouteAware {
  VideoPlayerController? _controller;
  ModalRoute<dynamic>? _route;
  bool _isVideoReady = false;
  bool _videoFailed = false;
  bool _routeIsVisible = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (_route == route) return;

    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }

    _route = route;
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didUpdateWidget(covariant VideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoAssetPath == widget.videoAssetPath) return;

    _releaseCurrentController();
    _videoFailed = false;

    if (_routeIsVisible) {
      unawaited(_initializeVideo());
    }
  }

  Future<void> _initializeVideo() async {
    final loadGeneration = ++_loadGeneration;
    if (!_routeIsVisible) return;

    final preloadedController = VideoBackground._takePreloadedController(
      widget.videoAssetPath,
    );

    if (preloadedController != null) {
      if (!_canUseController(loadGeneration)) {
        await preloadedController.dispose();
        return;
      }

      _startReadyController(preloadedController);
      return;
    }

    final preloadFuture =
        VideoBackground._preloadFutures[widget.videoAssetPath];
    if (preloadFuture != null) {
      await preloadFuture;

      if (!_canUseController(loadGeneration)) return;

      final finishedPreloadController =
          VideoBackground._takePreloadedController(widget.videoAssetPath);

      if (finishedPreloadController != null) {
        if (!_canUseController(loadGeneration)) {
          await finishedPreloadController.dispose();
          return;
        }

        _startReadyController(finishedPreloadController, notify: true);
        return;
      }
    }

    try {
      await VideoBackground._verifyAssetExists(widget.videoAssetPath);
    } catch (error, stackTrace) {
      VideoBackground._logVideoError(
        widget.videoAssetPath,
        'asset lookup',
        error,
        stackTrace,
      );

      if (!_canUseController(loadGeneration)) return;

      setState(() {
        _controller = null;
        _isVideoReady = false;
        _videoFailed = true;
      });
      return;
    }

    if (!_canUseController(loadGeneration)) return;

    final controller = VideoBackground._createController(widget.videoAssetPath);
    controller.addListener(_handleControllerUpdate);
    _controller = controller;

    try {
      await VideoBackground._prepareController(controller, shouldPlay: true);

      if (!_canUseController(loadGeneration)) {
        if (identical(_controller, controller)) {
          await _disposeController(controller);
        }
        return;
      }

      setState(() {
        _isVideoReady = true;
        _videoFailed = false;
      });
    } catch (error, stackTrace) {
      VideoBackground._logVideoError(
        widget.videoAssetPath,
        'initialize',
        error,
        stackTrace,
      );
      if (identical(_controller, controller)) {
        await _disposeController(controller);
      }

      if (!_canUseController(loadGeneration)) return;

      setState(() {
        if (identical(_controller, controller)) {
          _controller = null;
        }
        _isVideoReady = false;
        _videoFailed = true;
      });
    }
  }

  bool _canUseController(int loadGeneration) {
    return mounted && _routeIsVisible && loadGeneration == _loadGeneration;
  }

  void _startReadyController(
    VideoPlayerController controller, {
    bool notify = false,
  }) {
    controller.addListener(_handleControllerUpdate);

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

    unawaited(
      controller.play().catchError((Object error, StackTrace stackTrace) {
        VideoBackground._logVideoError(
          widget.videoAssetPath,
          'play',
          error,
          stackTrace,
        );
      }),
    );
  }

  void _handleControllerUpdate() {
    final controller = _controller;
    if (controller == null || _videoFailed || !controller.value.hasError) {
      return;
    }

    final error = StateError(
      controller.value.errorDescription ?? 'Unknown video player error.',
    );
    VideoBackground._logVideoError(widget.videoAssetPath, 'playback', error);
    _failCurrentController(controller);
  }

  void _failCurrentController(VideoPlayerController controller) {
    if (!mounted || !identical(_controller, controller)) return;

    setState(() {
      _controller = null;
      _isVideoReady = false;
      _videoFailed = true;
    });

    unawaited(_disposeController(controller));
  }

  void _releaseCurrentController() {
    _loadGeneration++;

    final controller = _controller;
    _controller = null;
    _isVideoReady = false;

    if (controller != null) {
      unawaited(_disposeController(controller));
    }
  }

  Future<void> _disposeController(VideoPlayerController controller) async {
    controller.removeListener(_handleControllerUpdate);
    await controller.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !_isVideoReady) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(
        controller.play().catchError((Object error, StackTrace stackTrace) {
          VideoBackground._logVideoError(
            widget.videoAssetPath,
            'resume playback',
            error,
            stackTrace,
          );
        }),
      );
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      controller.pause();
    }
  }

  @override
  void didPush() {
    _routeIsVisible = true;
  }

  @override
  void didPopNext() {
    _routeIsVisible = true;
    _videoFailed = false;
    unawaited(_initializeVideo());
  }

  @override
  void didPushNext() {
    _routeIsVisible = false;
    if (mounted) {
      setState(_releaseCurrentController);
    } else {
      _releaseCurrentController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _releaseCurrentController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.backgroundColor,
                  const Color(0xFF0E2416),
                  const Color(0xFF020504),
                ],
              ),
            ),
          ),
        ),
        if (widget.fallbackImageAssetPath != null)
          Positioned.fill(
            child: Image.asset(
              widget.fallbackImageAssetPath!,
              fit: BoxFit.cover,
            ),
          ),
        if (controller != null &&
            controller.value.isInitialized &&
            _isVideoReady &&
            !_videoFailed)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: 1,
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
