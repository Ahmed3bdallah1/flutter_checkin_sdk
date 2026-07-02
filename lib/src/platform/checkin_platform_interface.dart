import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../events/verification_event.dart';
import '../models/verification_session.dart';

/// Platform contract for the Checkin.com Flutter plugin.
abstract base class CheckinPlatform extends PlatformInterface {
  CheckinPlatform() : super(token: _token);

  static final Object _token = Object();
  static CheckinPlatform _instance = _PlaceholderCheckinPlatform();

  static CheckinPlatform get instance => _instance;

  static set instance(CheckinPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Stream of verification events from the native SDK.
  Stream<VerificationEvent> get events;

  /// Prepares the plugin bridge and event stream.
  ///
  /// The native Checkin.com SDK does not expose a separate initialize API.
  /// This method ensures the platform channel listeners are ready.
  Future<void> initialize();

  /// Starts a verification flow using [session] configuration.
  ///
  /// Maps to `GetIDSDK.startVerificationFlow()` on Android and iOS.
  Future<void> startVerification(VerificationSession session);

  /// Attempts to cancel an in-progress verification flow.
  ///
  /// TODO: Not documented in Checkin SDK.
  Future<void> cancel();
}

final class _PlaceholderCheckinPlatform extends CheckinPlatform {
  @override
  Stream<VerificationEvent> get events => const Stream.empty();

  @override
  Future<void> initialize() {
    throw UnimplementedError('CheckinPlatform has not been configured.');
  }

  @override
  Future<void> startVerification(VerificationSession session) {
    throw UnimplementedError('CheckinPlatform has not been configured.');
  }

  @override
  Future<void> cancel() {
    throw UnimplementedError('CheckinPlatform has not been configured.');
  }
}
