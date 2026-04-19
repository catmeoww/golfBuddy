// TODO: LLD §11 — route logs through Sentry breadcrumbs + local SQLite event log.
import 'dart:developer' as developer;

class Logger {
  const Logger(this.tag);
  final String tag;

  void info(String message) => developer.log(message, name: tag);
  void warn(String message) => developer.log('WARN: $message', name: tag);
  void error(String message, [Object? err, StackTrace? st]) =>
      developer.log(message, name: tag, error: err, stackTrace: st);
}
