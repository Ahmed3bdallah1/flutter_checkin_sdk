import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Shared logger for Checkin.com plugin diagnostics.
///
/// Only emits output in debug builds ([kDebugMode]).
final Logger checkinLogger = Logger(
  level: kDebugMode ? Level.debug : Level.off,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 100,
    colors: true,
    printEmojis: false,
  ),
);
