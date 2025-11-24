import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_quiz/main.dart'; // ← ЗАМЕНИТЕ на ваше настоящее имя пакета

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app starts without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login screen is shown initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that login screen elements are present
    expect(find.text('Quiz App'), findsOneWidget);
    expect(find.byType(TextField), findsAtLeast(1));
    expect(find.byType(ElevatedButton), findsAtLeast(1));
  });
}
