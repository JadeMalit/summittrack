import 'package:video_player/video_player.dart';

VideoPlayerController createTrailVideoController({
  required String source,
  required bool isLocal,
}) {
  return VideoPlayerController.networkUrl(Uri.parse(source));
}
