import 'package:equatable/equatable.dart';

/// Metadata attached to a verification session.
///
/// Maps to native `Metadata` on Android and iOS.
final class VerificationMetadata extends Equatable {
  const VerificationMetadata({
    this.externalId,
    this.customerId,
    this.labels = const {},
  });

  /// Links the verification to an identifier in your system.
  final String? externalId;

  /// Links the verification to a customer identifier in your system.
  final String? customerId;

  /// Custom key-value labels attached to the application.
  final Map<String, String> labels;

  Map<String, dynamic> toJson() => {
        if (externalId != null) 'externalId': externalId,
        if (customerId != null) 'customerId': customerId,
        if (labels.isNotEmpty) 'labels': labels,
      };

  @override
  List<Object?> get props => [externalId, customerId, labels];
}
