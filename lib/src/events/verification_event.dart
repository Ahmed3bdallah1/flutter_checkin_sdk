import 'package:equatable/equatable.dart';

import '../models/verification_error.dart';
import '../models/verification_session.dart';

/// Events emitted by the Checkin.com native SDK during a verification flow.
///
/// Documented native callbacks:
/// - Android `BroadcastReceiverListener`
/// - iOS `GetIDSDKDelegate`
sealed class VerificationEvent extends Equatable {
  const VerificationEvent();

  factory VerificationEvent.fromJson(Map<dynamic, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'verificationStarted' => const VerificationStarted(),
      'verificationCompleted' => VerificationCompleted(
          VerificationResult.fromJson(
            json['result'] as Map<dynamic, dynamic>? ?? json,
          ),
        ),
      'verificationCancelled' => const VerificationCancelled(),
      'verificationFailed' => VerificationFailed(
          VerificationError.fromJson(
            json['error'] as Map<dynamic, dynamic>? ?? json,
          ),
        ),
      _ => UnknownError(
          VerificationError(
            code: type ?? 'UNKNOWN',
            message: 'Received an unrecognized event from the native SDK.',
            nativeError: json.toString(),
          ),
        ),
    };
  }

  @override
  List<Object?> get props => [];
}

/// Emitted when the native SDK reports `verificationFlowStart()` /
/// `verificationFlowDidStart()`.
final class VerificationStarted extends VerificationEvent {
  const VerificationStarted();
}

/// Emitted when the native SDK reports `verificationFlowComplete()` /
/// `verificationFlowDidComplete(_:)`.
final class VerificationCompleted extends VerificationEvent {
  const VerificationCompleted(this.result);

  final VerificationResult result;

  @override
  List<Object?> get props => [result];
}

/// Emitted when the native SDK reports `verificationFlowCancel()` /
/// `verificationFlowDidCancel()`.
final class VerificationCancelled extends VerificationEvent {
  const VerificationCancelled();
}

/// Emitted when the native SDK reports `verificationFlowFail()` /
/// `verificationFlowDidFail(_:)`.
final class VerificationFailed extends VerificationEvent {
  const VerificationFailed(this.error);

  final VerificationError error;

  @override
  List<Object?> get props => [error];
}

// ---------------------------------------------------------------------------
// The event types below are NOT documented in the Checkin.com native SDK.
// They are reserved for future SDK support and are never emitted today.
// ---------------------------------------------------------------------------

/// TODO: Not documented in Checkin SDK.
final class DocumentUploaded extends VerificationEvent {
  const DocumentUploaded();

  @override
  List<Object?> get props => [];
}

/// TODO: Not documented in Checkin SDK.
final class FaceScanStarted extends VerificationEvent {
  const FaceScanStarted();

  @override
  List<Object?> get props => [];
}

/// TODO: Not documented in Checkin SDK.
final class FaceScanCompleted extends VerificationEvent {
  const FaceScanCompleted();

  @override
  List<Object?> get props => [];
}

/// TODO: Not documented in Checkin SDK.
final class Timeout extends VerificationEvent {
  const Timeout();

  @override
  List<Object?> get props => [];
}

/// TODO: Not documented in Checkin SDK.
final class SdkClosed extends VerificationEvent {
  const SdkClosed();

  @override
  List<Object?> get props => [];
}

/// Emitted when the plugin receives an event it cannot map to a known type.
final class UnknownError extends VerificationEvent {
  const UnknownError(this.error);

  final VerificationError error;

  @override
  List<Object?> get props => [error];
}
