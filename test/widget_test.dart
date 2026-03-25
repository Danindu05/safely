import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:safely/screens/common/onboarding_screen.dart';

void main() {
  testWidgets('onboarding screen renders key content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onContinue: () {})),
    );

    expect(find.text('Welcome to Safely'), findsOneWidget);
    expect(find.text('What gets shared'), findsOneWidget);
    expect(find.text('When guardians are notified'), findsOneWidget);
  });
}
