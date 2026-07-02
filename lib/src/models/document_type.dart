import 'package:equatable/equatable.dart';

/// Document types supported by the Checkin.com native SDK
/// when configuring [AcceptableDocuments].
enum DocumentType {
  passport('passport'),
  idCard('idCard');

  const DocumentType(this.nativeValue);

  /// Value sent to the native bridge.
  final String nativeValue;

  static DocumentType? fromNativeValue(String value) {
    for (final type in DocumentType.values) {
      if (type.nativeValue == value) {
        return type;
      }
    }
    return null;
  }
}

/// Country-specific document restrictions passed to
/// `GetIDSDK.startVerificationFlow(acceptableDocuments:)`.
final class AcceptableDocuments extends Equatable {
  const AcceptableDocuments(this.documentsByCountry);

  /// Keys are ISO country codes (e.g. `EST`) or `default`.
  final Map<String, List<DocumentType>> documentsByCountry;

  Map<String, List<String>> toJson() => documentsByCountry.map(
        (country, documents) => MapEntry(
          country,
          documents.map((document) => document.nativeValue).toList(),
        ),
      );

  @override
  List<Object?> get props => [documentsByCountry];
}
