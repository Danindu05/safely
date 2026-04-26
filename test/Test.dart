import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/main.dart';

void main() {
  group('App Tests', () {

    testWidgets('App should load home screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Button click should update UI', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();

     
      expect(find.text('Clicked'), findsOneWidget);
    });

  });
}