// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:studymate/main.dart';

void main() {
  testWidgets('StudyMate app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(StudyMateApp());

    // Verify that the app loads (this is a basic test)
    // We can expand this later once Firebase is properly configured
    expect(find.text('Loading StudyMate...'), findsOneWidget);
  });
}
