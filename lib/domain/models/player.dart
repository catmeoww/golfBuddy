// Coach-persona revision: PlayerType distinguishes the coach from
// subjects of coaching (child/student/friend), since the coach's
// workflow and view differ from the student's.
enum PlayerType {
  self,
  child,
  student,
  friend;

  static PlayerType parse(String raw) {
    return PlayerType.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => PlayerType.student,
    );
  }
}

class Player {
  const Player({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
    this.avatarPath,
  });

  final String id;
  final String name;
  final PlayerType type;
  final String? avatarPath;
  final DateTime createdAt;
}
