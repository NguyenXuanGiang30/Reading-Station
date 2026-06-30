/// Logger Service - Structured logging for Flutter
library;

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels enum
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  critical(4, 'CRITICAL');

  final int priority;
  final String label;
  
  const LogLevel(this.priority, this.label);
}

/// Logger service with different log levels
class Logger {
  final String _tag;
  final LogLevel _minLevel;
  
  Logger(this._tag, {LogLevel minLevel = LogLevel.debug}) 
      : _minLevel = minLevel;
  
  /// Create a logger with tag
  static Logger getLogger(String tag) {
    return Logger(tag);
  }
  
  /// Debug log
  void debug(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, data: data);
  }
  
  /// Info log
  void info(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, data: data);
  }
  
  /// Warning log
  void warning(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, data: data);
  }
  
  /// Error log
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(
      LogLevel.error, 
      message, 
      error: error, 
      stackTrace: stackTrace,
      data: data,
    );
  }
  
  /// Critical log
  void critical(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(
      LogLevel.critical, 
      message, 
      error: error, 
      stackTrace: stackTrace,
      data: data,
    );
  }
  
  /// Log with exception
  void exception(String message, Object exception, {StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(
      LogLevel.error,
      message,
      error: exception,
      stackTrace: stackTrace,
      data: data,
    );
  }
  
  void _log(
    LogLevel level, 
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Skip if below minimum level
    if (level.priority < _minLevel.priority) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final formattedMessage = '[$timestamp] [${level.label}] [$_tag] $message';
    
    // Build additional data
    String additionalInfo = '';
    if (data != null && data.isNotEmpty) {
      additionalInfo = ' | Data: ${_formatData(data)}';
    }
    if (error != null) {
      additionalInfo += ' | Error: $error';
    }
    
    final fullMessage = '$formattedMessage$additionalInfo';
    
    // Log based on level
    switch (level) {
      case LogLevel.debug:
      case LogLevel.info:
        developer.log(fullMessage, name: _tag);
        break;
      case LogLevel.warning:
        developer.log(fullMessage, name: _tag, level: 900);
        break;
      case LogLevel.error:
      case LogLevel.critical:
        developer.log(
          fullMessage, 
          name: _tag, 
          level: level == LogLevel.critical ? 1200 : 1000,
          stackTrace: stackTrace,
        );
        break;
    }
    
    // Also print to console in debug mode
    if (kDebugMode) {
      _printToConsole(level, fullMessage, stackTrace);
    }
  }
  
  String _formatData(Map<String, dynamic> data) {
    return data.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
  }
  
  void _printToConsole(LogLevel level, String message, StackTrace? stackTrace) {
    final prefix = _getConsolePrefix(level);
    debugPrint('$prefix $message');
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
  
  String _getConsolePrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '\x1B[36m[DEBUG]\x1B[0m'; // Cyan
      case LogLevel.info:
        return '\x1B[32m[INFO]\x1B[0m';  // Green
      case LogLevel.warning:
        return '\x1B[33m[WARN]\x1B[0m';  // Yellow
      case LogLevel.error:
        return '\x1B[31m[ERROR]\x1B[0m'; // Red
      case LogLevel.critical:
        return '\x1B[35m[CRITICAL]\x1B[0m'; // Magenta
    }
  }
}

/// Global logger instance
class AppLogger {
  static final Map<String, Logger> _loggers = {};
  
  static Logger getLogger(String tag) {
    if (!_loggers.containsKey(tag)) {
      _loggers[tag] = Logger(tag);
    }
    return _loggers[tag]!;
  }
  
  // Predefined loggers for common tags
  static Logger get auth => getLogger('Auth');
  static Logger get api => getLogger('API');
  static Logger get network => getLogger('Network');
  static Logger get database => getLogger('Database');
  static Logger get ui => getLogger('UI');
  static Logger get storage => getLogger('Storage');
  static Logger get navigation => getLogger('Navigation');
  
  /// Initialize logger with minimum level
  static void initialize({LogLevel minLevel = LogLevel.debug}) {
    // Set global log level by creating a default logger
    getLogger('App').info('Logger initialized with min level: ${minLevel.label}');
  }
}

/// Extension for easy logging in classes
extension LoggerExtension on Object {
  Logger get logger => AppLogger.getLogger(runtimeType.toString());
}

// Usage example:
// class MyService {
//   void doSomething() {
//     logger.info('Doing something', data: {'key': 'value'});
//   }
//   
//   void handleError(Exception e) {
//     logger.exception('Error occurred', e);
//   }
// }
