class Tournament {
  const Tournament({
    required this.id,
    required this.name,
    required this.date,
    required this.createdAt,
    this.location,
    this.notes,
  });

  final String id;
  final String name;
  final DateTime date;
  final String? location;
  final String? notes;
  final DateTime createdAt;
}
