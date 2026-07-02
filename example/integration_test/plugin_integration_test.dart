import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_checkin_sdk/flutter_checkin_sdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('initialize completes', (WidgetTester tester) async {
    final sdk = FlutterCheckinSdk();
    await sdk.initialize();
  });
}
