import 'package:flutter_test/flutter_test.dart';

import 'package:myroxas/main.dart';

void main() {
  testWidgets('MyRoxas app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyRoxasApp());

    // Verify that our app loads with the greeting
    expect(find.textContaining('Roxasnon'), findsOneWidget);
  });
}
