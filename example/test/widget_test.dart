import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_checkin_sdk_example/main.dart';

void main() {
  testWidgets('Verification screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CheckinExampleApp()),
    );

    expect(find.text('Checkin.com Verification'), findsOneWidget);
    expect(find.text('Start verification'), findsOneWidget);
  });
}
