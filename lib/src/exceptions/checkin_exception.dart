import 'package:equatable/equatable.dart';

/// Base class for all Checkin.com plugin exceptions.
///
/// Platform exceptions are converted into these types before reaching app code.
sealed class CheckinException implements Exception, Equatable {
  const CheckinException({
    required this.errorCode,
    required this.message,
    this.nativeError,
  });

  final String errorCode;
  final String message;
  final String? nativeError;

  @override
  List<Object?> get props => [errorCode, message, nativeError];

  @override
  bool? get stringify => true;

  @override
  String toString() => '$runtimeType($errorCode): $message';
}

/// Thrown when plugin initialization fails.
final class InitializationException extends CheckinException {
  const InitializationException({
    required super.errorCode,
    required super.message,
    super.nativeError,
  });
}

/// Thrown when a verification flow fails to start or complete.
final class VerificationException extends CheckinException {
  const VerificationException({
    required super.errorCode,
    required super.message,
    super.nativeError,
  });
}

/// Thrown when a required permission (e.g. camera) is denied.
///
/// Maps to native `GetIDError.DENY_PERMISSION` on Android.
final class CameraPermissionDenied extends CheckinException {
  const CameraPermissionDenied({
    super.errorCode = 'DENY_PERMISSION',
    super.message = 'A required permission was denied.',
    super.nativeError,
  });
}

/// Thrown when the SDK cannot communicate with the Checkin.com backend.
///
/// Maps to native `FAILED_TO_SEND_APPLICATION` / `failedToSendApplication`.
final class NetworkException extends CheckinException {
  const NetworkException({
    required super.errorCode,
    required super.message,
    super.nativeError,
  });
}

/// Thrown when configuration values such as API URL, flow name, or SDK key
/// are invalid.
final class InvalidConfiguration extends CheckinException {
  const InvalidConfiguration({
    required super.errorCode,
    required super.message,
    super.nativeError,
  });
}

/// Thrown when the JWT or liveness token has expired.
///
/// Maps to native `TOKEN_EXPIRED` / `tokenExpired`.
final class SessionExpired extends CheckinException {
  const SessionExpired({
    required super.errorCode,
    required super.message,
    super.nativeError,
  });
}

/// Thrown when the native SDK does not support a requested operation.
final class UnsupportedCheckinException extends CheckinException {
  const UnsupportedCheckinException({
    required super.errorCode,
    required super.message,
    super.nativeError,
  });
}

/// Thrown for unrecognized or unexpected native errors.
final class UnknownCheckinException extends CheckinException {
  const UnknownCheckinException({
    required super.errorCode,
    required super.message,
    super.nativeError,
  });
}

/// Converts a native [GetIDError] code into a strongly typed [CheckinException].
CheckinException mapNativeErrorToException({
  required String code,
  required String message,
  String? nativeError,
}) {
  return switch (code) {
    'INVALID_KEY' ||
    'invalidKey' ||
    'INVALID_TOKEN' ||
    'invalidToken' ||
    'FLOW_NOT_FOUND' ||
    'flowNotFound' ||
    'invalidURL' ||
    'invalidFlowName' =>
      InvalidConfiguration(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
    'TOKEN_EXPIRED' ||
    'tokenExpired' ||
    'INVALID_LIVENESS_TOKEN' ||
    'invalidLivenessToken' =>
      SessionExpired(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
    'DENY_PERMISSION' || 'denyPermission' => CameraPermissionDenied(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
    'FAILED_TO_SEND_APPLICATION' ||
    'failedToSendApplication' ||
    'FAILED_TO_RECEIVE_CONFIGURATION' ||
    'failedToReceiveConfiguration' =>
      NetworkException(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
    'UNSUPPORTED_SCHEMA_VERSION' ||
    'unsupportedSchemaVersion' ||
    'UNSUPPORTED_LIVENESS_VERSION' ||
    'unsupportedLivenessVersion' =>
      InitializationException(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
    'CUSTOMER_ID_ALREADY_EXIST' ||
    'applicationWithThisCustomerIdAlreadyExists' ||
    'NO_NFC_SUPPORT' ||
    'noNfcSupport' =>
      VerificationException(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
    'UNSUPPORTED' => UnsupportedCheckinException(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
    _ => UnknownCheckinException(
        errorCode: code,
        message: message,
        nativeError: nativeError,
      ),
  };
}

/// Converts a [PlatformException]-like map from the method channel into
/// a [CheckinException].
CheckinException mapPlatformException({
  required String code,
  required String message,
  String? details,
}) {
  return mapNativeErrorToException(
    code: code,
    message: message,
    nativeError: details,
  );
}
