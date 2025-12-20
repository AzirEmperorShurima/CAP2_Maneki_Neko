import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

part 'custom_printer.dart';

/// Global logger instance với CustomPrinter
/// Sử dụng để log trong toàn bộ app
final logger = Logger(
  printer: CustomPrinter(
    printTime: true,
    methodCount: 8,
    errorMethodCount: 8,
    lineLength: 120,
    colors: false,
    printEmojis: true,
  ),
);

/// Helper function để format Map thành JSON đẹp
String _prettyJson(Map<dynamic, dynamic> map) {
  final encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(map);
}

/// Log debug message
void logD(dynamic message) {
  _log(Level.debug, message);
}

/// Log warning message
void logW(dynamic message) {
  _log(Level.warning, message);
}

/// Log error message
void logE(dynamic message, [StackTrace? stackTrace, dynamic error]) {
  _log(Level.error, message, error, stackTrace);
}

/// Internal log function với smart formatting
void _log(Level level, dynamic message,
    [dynamic error, StackTrace? stackTrace]) {
  if (kDebugMode) {
    if (message is List || message is Iterable) {
      logger.log(
        level,
        message.map((e) {
          if (e is Map) return _prettyJson(e);
          dynamic mess = e;
          try {
            if (![String, int, num, double, List, Map, Set]
                .contains(mess.runtimeType)) {
              mess = e.toJson();
            }
          } catch (_) {}

          return mess is Map ? _prettyJson(mess) : mess;
        }).toList(),
        time: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      );
    } else if (message is Map) {
      final json = <String, dynamic>{};
      message.forEach((key, value) {
        dynamic v = value;
        try {
          if (![String, int, num, double, List, Map, Set]
              .contains(v.runtimeType)) {
            v = value.toJson();
          }
        } catch (_) {}
        json[key.toString()] = v;
      });
      logger.log(
        level,
        _prettyJson(json),
        time: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      );
    } else if (message is Iterable<Map>) {
      logger.log(
        level,
        message.map((e) => _prettyJson(e)).toList(),
        time: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      dynamic v = message;
      try {
        if (![String, int, num, double, List, Map, Set]
            .contains(v.runtimeType)) {
          v = message.toJson();
        }
      } catch (_) {}

      logger.log(
        level,
        v,
        time: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

