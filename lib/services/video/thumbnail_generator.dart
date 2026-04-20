import 'dart:io';

import 'package:flutter/services.dart';

/// Generates a JPEG thumbnail for a session's video by pulling the
/// first sync frame via the Android MediaMetadataRetriever platform
/// channel. Non-Android platforms no-op.
class ThumbnailGenerator {
  const ThumbnailGenerator();

  static const MethodChannel _channel =
      MethodChannel('app.golfbuddy/frame_extractor');

  Future<bool> generate({
    required String videoPath,
    required String outputPath,
    int maxDim = 512,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      await _channel.invokeMethod<String>('thumbnail', {
        'videoPath': videoPath,
        'outputPath': outputPath,
        'maxDim': maxDim,
      });
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
