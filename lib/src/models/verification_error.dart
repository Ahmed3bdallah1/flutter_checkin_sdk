import 'package:equatable/equatable.dart';

import '../utils/json_readers.dart';

/// Error details reported by the native Checkin.com SDK.
final class VerificationError extends Equatable {
  const VerificationError({
    required this.code,
    required this.message,
    this.nativeError,
  });

  /// Machine-readable error code from the native SDK.
  final String code;

  /// Human-readable error description.
  final String message;

  /// Raw native error representation, when available.
  final String? nativeError;

  factory VerificationError.fromJson(Map<dynamic, dynamic> json) {
    return VerificationError(
      code: readJsonString(json['code']) ?? 'UNKNOWN',
      message: readJsonString(json['message']) ?? 'An unknown error occurred.',
      nativeError: readJsonString(json['nativeError']),
    );
  }

  @override
  List<Object?> get props => [code, message, nativeError];
}
