import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: init Sentry (HLD §7 crash reporting) once DSN is provisioned.
  runApp(const ProviderScope(child: GolfBuddyApp()));
}
