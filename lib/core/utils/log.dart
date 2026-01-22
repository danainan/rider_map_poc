import 'package:flutter/foundation.dart';

/// Logging utility class
class Log {
  Log._();

  /// Log debug message
  static void d(String message, {String? tag}) {
    if (kDebugMode) {
      print('[DEBUG] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log info message
  static void i(String message, {String? tag}) {
    if (kDebugMode) {
      print('[INFO] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log warning message
  static void w(String message, {String? tag}) {
    if (kDebugMode) {
      print('[WARNING] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  /// Log error message
  static void e(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('[ERROR] ${tag != null ? '[$tag] ' : ''}$message');
      if (error != null) {
        print('Error: $error');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }
}
