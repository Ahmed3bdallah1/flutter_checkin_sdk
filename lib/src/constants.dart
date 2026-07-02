/// Internal channel names used by the plugin bridge.
abstract final class CheckinChannels {
  static const String methodChannel = 'flutter_checkin_sdk';
  static const String eventChannel = 'flutter_checkin_sdk/events';
}

/// Method names exposed over the [CheckinChannels.methodChannel].
abstract final class CheckinMethods {
  static const String initialize = 'initialize';
  static const String startVerification = 'startVerification';
  static const String cancel = 'cancel';
}

/// Event type identifiers sent over the [CheckinChannels.eventChannel].
abstract final class CheckinEventTypes {
  static const String verificationStarted = 'verificationStarted';
  static const String verificationCompleted = 'verificationCompleted';
  static const String verificationCancelled = 'verificationCancelled';
  static const String verificationFailed = 'verificationFailed';
}
