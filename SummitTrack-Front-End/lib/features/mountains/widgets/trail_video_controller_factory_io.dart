import 'dart:io';

import 'package:video_player/video_player.dart';

VideoPlayerController createTrailVideoController({
  required String source,
  required bool isLocal,
}) {
  if (!isLocal) {
    return VideoPlayerController.networkUrl(Uri.parse(source));
  }

  final uri = Uri.tryParse(source);
  if (uri != null && uri.scheme == 'content') {
    return VideoPlayerController.contentUri(uri);
  }
  if (uri != null && uri.scheme == 'file') {
    return VideoPlayerController.file(File.fromUri(uri));
  }

  return VideoPlayerController.file(File(source));
}
