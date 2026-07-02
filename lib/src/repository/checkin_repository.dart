import '../events/verification_event.dart';
import '../exceptions/checkin_exception.dart';
import '../models/verification_session.dart';
import '../platform/checkin_platform_interface.dart';

/// Repository layer between the public API and the platform bridge.
class CheckinRepository {
  CheckinRepository({CheckinPlatform? platform})
      : _platform = platform ?? CheckinPlatform.instance;

  final CheckinPlatform _platform;

  Stream<VerificationEvent> get events => _platform.events;

  Future<void> initialize() => _platform.initialize();

  Future<void> startVerification(VerificationSession session) {
    _validateSession(session);
    return _platform.startVerification(session);
  }

  /// TODO: Not documented in Checkin SDK.
  Future<void> cancel() => _platform.cancel();

  void _validateSession(VerificationSession session) {
    if (session.apiUrl.trim().isEmpty) {
      throw const InvalidConfiguration(
        errorCode: 'INVALID_API_URL',
        message: 'apiUrl must not be empty.',
      );
    }
    if (session.flowName.trim().isEmpty) {
      throw const InvalidConfiguration(
        errorCode: 'INVALID_FLOW_NAME',
        message: 'flowName must not be empty.',
      );
    }
    if (session.auth.value.trim().isEmpty) {
      throw const InvalidConfiguration(
        errorCode: 'INVALID_AUTH',
        message: 'Authentication value must not be empty.',
      );
    }
  }
}
