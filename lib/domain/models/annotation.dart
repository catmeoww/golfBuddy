class Annotation {
  const Annotation({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.createdAt,
    this.timestampMs,
  });

  final String id;
  final String sessionId;
  // null = session-level note; non-null = anchored to a video timestamp.
  final int? timestampMs;
  final String text;
  final DateTime createdAt;
}
