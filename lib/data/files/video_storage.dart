// TODO: LLD §5 — path resolution + cleanup.
// Layout: {appDocs}/swings/{sessionId}.mp4 and thumbnails alongside.
class VideoStorage {
  Future<String> resolveVideoPath(String sessionId) async {
    throw UnimplementedError('VideoStorage.resolveVideoPath');
  }

  Future<void> delete(String sessionId) async {
    throw UnimplementedError('VideoStorage.delete');
  }
}
