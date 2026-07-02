import 'package:flutter_checkin_sdk/flutter_checkin_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VerificationSession serializes auth payload', () {
    const session = VerificationSession(
      apiUrl: 'https://company-name.getid.ee',
      auth: CheckinAuth.jwt('token'),
      flowName: 'IDscan-InstantLiv',
      locale: 'en',
      metadata: VerificationMetadata(externalId: 'user-1'),
    );

    final json = session.toJson();

    expect(json['apiUrl'], 'https://company-name.getid.ee');
    expect(json['flowName'], 'IDscan-InstantLiv');
    expect(json['auth'], {'type': 'jwt', 'value': 'token'});
    expect(json['metadata'], {'externalId': 'user-1'});
  });

  test('VerificationEvent parses completed event', () {
    final event = VerificationEvent.fromJson({
      'type': 'verificationCompleted',
      'result': {'applicationId': 'app-123'},
    });

    expect(event, isA<VerificationCompleted>());
    expect((event as VerificationCompleted).result.applicationId, 'app-123');
  });

  test('VerificationResult coerces numeric applicationId', () {
    final result = VerificationResult.fromJson({
      'applicationId': 12345,
    });

    expect(result.applicationId, '12345');
  });
}
