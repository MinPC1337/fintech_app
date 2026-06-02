import 'package:flutter/foundation.dart';

/// Debug logs for push / FCM. Filter Debug Console with: `[Push]`
abstract final class PushDebug {
  static const tag = '[Push]';

  static void log(String step, [Object? detail]) {
    if (!kDebugMode) return;
    if (detail == null) {
      debugPrint('$tag $step');
      return;
    }
    debugPrint('$tag $step | $detail');
  }

  static void ok(String step, [Object? detail]) => log('OK $step', detail);

  static void warn(String step, [Object? detail]) => log('WARN $step', detail);

  static void fail(String step, [Object? detail]) => log('FAIL $step', detail);

  /// Short token preview — never log full FCM token in production builds.
  static String maskToken(String? token) {
    if (token == null || token.isEmpty) return '(empty)';
    if (token.length <= 16) return '***';
    return '${token.substring(0, 8)}…${token.substring(token.length - 6)}';
  }
}
