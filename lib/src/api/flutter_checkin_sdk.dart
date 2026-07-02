import '../events/verification_event.dart';
import '../models/checkin_auth.dart';
import '../models/document_type.dart';
import '../models/verification_metadata.dart';
import '../models/verification_session.dart';
import '../platform/checkin_platform.dart';
import '../repository/checkin_repository.dart';

export '../events/verification_event.dart';
export '../exceptions/checkin_exception.dart';
export '../models/checkin_auth.dart';
export '../models/document_type.dart';
export '../models/verification_error.dart';
export '../models/verification_metadata.dart';
export '../models/verification_session.dart';

/// Public entry point for the Checkin.com Flutter SDK.
///
/// Example:
/// ```dart
/// final sdk = FlutterCheckinSdk();
/// await sdk.initialize();
/// sdk.events.listen((event) { ... });
/// await sdk.startVerification(
///   apiUrl: 'https://company-name.getid.ee',
///   auth: CheckinAuth.sdkKey('YOUR_SDK_KEY'),
///   flowName: 'YOUR_FLOW',
/// );
/// ```
class FlutterCheckinSdk {
  FlutterCheckinSdk({CheckinRepository? repository})
      : _repository = repository ?? CheckinRepository() {
    ensureCheckinPlatformRegistered();
  }

  final CheckinRepository _repository;

  /// Verification events emitted by the native Checkin.com SDK.
  Stream<VerificationEvent> get events => _repository.events;

  /// Prepares the plugin bridge for verification flows.
  Future<void> initialize() => _repository.initialize();

  /// Starts a Checkin.com verification flow.
  ///
  /// Maps to `GetIDSDK.startVerificationFlow()` on Android and iOS.
  Future<void> startVerification({
    required String apiUrl,
    required CheckinAuth auth,
    required String flowName,
    String? locale,
    String? dictionary,
    Map<String, String> profileData = const {},
    VerificationMetadata? metadata,
    AcceptableDocuments? acceptableDocuments,
  }) {
    return _repository.startVerification(
      VerificationSession(
        apiUrl: apiUrl,
        auth: auth,
        flowName: flowName,
        locale: locale,
        dictionary: dictionary,
        profileData: profileData,
        metadata: metadata,
        acceptableDocuments: acceptableDocuments,
      ),
    );
  }

  /// Attempts to cancel an in-progress verification flow.
  ///
  /// TODO: Not documented in Checkin SDK.
  Future<void> cancel() => _repository.cancel();
}
