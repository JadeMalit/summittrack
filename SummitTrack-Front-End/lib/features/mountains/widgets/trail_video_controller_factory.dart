import 'package:video_player/video_player.dart';

import 'trail_video_controller_factory_stub.dart'
    if (dart.library.io) 'trail_video_controller_factory_io.dart'
    if (dart.library.html) 'trail_video_controller_factory_web.dart'
    as platform_factory;

VideoPlayerController createTrailVideoController({
  required String source,
  required bool isLocal,
}) {
  return platform_factory.createTrailVideoController(
    source: source,
    isLocal: isLocal,
  );
}
