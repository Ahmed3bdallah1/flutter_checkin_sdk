import '../events/verification_event.dart';
import '../exceptions/checkin_exception.dart';
import '../models/verification_session.dart';
import '../platform/checkin_platform.dart';
import '../platform/checkin_platform_interface.dart';
import '../utils/checkin_logger.dart';

/// Repository layer between the public API and the platform bridge.
class CheckinRepository {
  CheckinRepository({CheckinPlatform? platform})
      : _platformOverride = platform;

  final CheckinPlatform? _platformOverride;

  CheckinPlatform get _platform {
    ensureCheckinPlatformRegistered();
    return _platformOverride ?? CheckinPlatform.instance;
  }

  Stream<VerificationEvent> get events => _platform.events;

  Future<void> initialize() {
    checkinLogger.i('Repository initialize');
    return _platform.initialize();
  }

  Future<void> startVerification(VerificationSession session) {
    _validateSession(session);
    checkinLogger.d('Repository startVerification: ${session.toJson()}');
    return _platform.startVerification(session);
  }

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
