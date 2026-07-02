import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_checkin_sdk/src/exceptions/checkin_exception.dart';
import 'package:flutter_checkin_sdk/src/models/checkin_auth.dart';
import 'package:flutter_checkin_sdk/src/models/verification_session.dart';
import 'package:flutter_checkin_sdk/src/platform/checkin_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel methodChannel;
  late MethodChannelCheckinPlatform platform;

  setUp(() {
    methodChannel = const MethodChannel('flutter_checkin_sdk');
    platform = MethodChannelCheckinPlatform(methodChannel: methodChannel);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
      switch (call.method) {
        case 'initialize':
          return null;
        case 'startVerification':
          return null;
        case 'cancel':
          throw PlatformException(
            code: 'UNSUPPORTED',
            message: 'cancel() is not documented in the Checkin.com native SDK.',
          );
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('initialize completes successfully', () async {
    await expectLater(platform.initialize(), completes);
  });

  test('startVerification sends session payload', () async {
    const session = VerificationSession(
      apiUrl: 'https://company-name.getid.ee',
      auth: CheckinAuth.sdkKey('sdk-key'),
      flowName: 'test-flow',
    );

    await expectLater(platform.startVerification(session), completes);
  });

  test('cancel maps platform exception to CheckinException', () async {
    expect(
      () => platform.cancel(),
      throwsA(isA<UnsupportedCheckinException>()),
    );
  });
}
