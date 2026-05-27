// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:app_weight_scale/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // App has repeating animations, so pumpAndSettle() will time out.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Weight Scale'), findsOneWidget);
    expect(find.text('Tare / Zero'), findsOneWidget);
    expect(find.text('Measure Weight'), findsOneWidget);
  });
}
