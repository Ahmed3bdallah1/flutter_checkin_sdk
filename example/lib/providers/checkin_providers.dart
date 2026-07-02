import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_checkin_sdk/flutter_checkin_sdk.dart';

final checkinSdkProvider = Provider<FlutterCheckinSdk>((ref) {
  final sdk = FlutterCheckinSdk();
  ref.onDispose(() {
    // The SDK does not expose a dispose API in the native documentation.
  });
  return sdk;
});

final verificationStatusProvider =
    StateProvider<VerificationStatus>((ref) => VerificationStatus.idle);

final lastApplicationIdProvider = StateProvider<String?>((ref) => null);

final lastErrorProvider = StateProvider<String?>((ref) => null);

final eventLogProvider = StateProvider<List<String>>((ref) => []);
