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
}
