import 'package:equatable/equatable.dart';

import 'checkin_auth.dart';
import 'document_type.dart';
import 'verification_metadata.dart';

/// High-level verification status for UI state management.
///
/// The native SDK does not expose granular step callbacks. Use these values
/// in your app layer when reacting to [VerificationEvent]s.
enum VerificationStatus {
  idle,
  initializing,
  inProgress,
  completed,
  cancelled,
  failed,
}

/// Configuration for a single verification session.
///
/// Maps to `GetIDSDK.startVerificationFlow()` on Android and iOS.
final class VerificationSession extends Equatable {
  const VerificationSession({
    required this.apiUrl,
    required this.auth,
    required this.flowName,
    this.locale,
    this.dictionary,
    this.profileData = const {},
    this.metadata,
    this.acceptableDocuments,
  });

  /// Checkin.com API URL (e.g. `https://company-name.getid.ee`).
  final String apiUrl;

  /// SDK key or JWT used to authenticate the flow.
  final CheckinAuth auth;

  /// Flow name configured in the Checkin.com Dashboard.
  final String flowName;

  /// Optional locale override (e.g. `en`, `et`).
  final String? locale;

  /// Optional custom dictionary name uploaded to Checkin.com.
  final String? dictionary;

  /// Profile data used to prefill or cross-check user information.
  final Map<String, String> profileData;

  /// Optional metadata such as `externalId`, `customerId`, and labels.
  final VerificationMetadata? metadata;

  /// Optional per-country document restrictions.
  final AcceptableDocuments? acceptableDocuments;

  Map<String, dynamic> toJson() => {
        'apiUrl': apiUrl,
        'auth': auth.toJson(),
        'flowName': flowName,
        if (locale != null) 'locale': locale,
        if (dictionary != null) 'dictionary': dictionary,
        if (profileData.isNotEmpty) 'profileData': profileData,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (acceptableDocuments != null)
          'acceptableDocuments': acceptableDocuments!.toJson(),
      };

  @override
  List<Object?> get props => [
        apiUrl,
        auth,
        flowName,
        locale,
        dictionary,
        profileData,
        metadata,
        acceptableDocuments,
      ];
}

/// Result returned when a verification flow completes successfully.
///
/// The native SDK only returns an `applicationId`. Fetch the full verification
/// result from your backend using the Checkin.com API.
final class VerificationResult extends Equatable {
  const VerificationResult({
    required this.applicationId,
  });

  /// Application identifier used to query verification status on your backend.
  final String applicationId;

  factory VerificationResult.fromJson(Map<dynamic, dynamic> json) {
    return VerificationResult(
      applicationId: json['applicationId'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [applicationId];
}
