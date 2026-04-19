import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';

// Single app-scoped Drift database. See LLD §5 for schema.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// Example provider — swap with real app-version source when wiring Settings.
final appVersionProvider = Provider<String>((ref) => '0.1.0');
