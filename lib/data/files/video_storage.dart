import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Layout per LLD §5:
//   {appDocs}/swings/{sessionId}.mp4
//   {appDocs}/swings/{sessionId}.thumb.jpg
class VideoStorage {
  Future<Directory> _swingsDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'swings'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> resolveVideoPath(String sessionId) async {
    final dir = await _swingsDir();
    return p.join(dir.path, '$sessionId.mp4');
  }

  Future<String> resolveThumbPath(String sessionId) async {
    final dir = await _swingsDir();
    return p.join(dir.path, '$sessionId.thumb.jpg');
  }

  Future<int> sizeFor(String sessionId) async {
    var total = 0;
    final video = File(await resolveVideoPath(sessionId));
    final thumb = File(await resolveThumbPath(sessionId));
    if (await video.exists()) total += await video.length();
    if (await thumb.exists()) total += await thumb.length();
    return total;
  }

  Future<int> totalBytes() async {
    final dir = await _swingsDir();
    var total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<void> delete(String sessionId) async {
    final video = File(await resolveVideoPath(sessionId));
    final thumb = File(await resolveThumbPath(sessionId));
    if (await video.exists()) {
      await video.delete();
    }
    if (await thumb.exists()) {
      await thumb.delete();
    }
  }

  Future<void> clearAll() async {
    final dir = await _swingsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await _swingsDir();
  }
}
