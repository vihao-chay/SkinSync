import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_skinasync/main.dart';

void main() {
  testWidgets('shows welcome content after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const SkinSyncApp());
    await tester.pump(const Duration(milliseconds: 950));

    expect(find.text('SkinSync'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('login flow reaches skin profile setup', (WidgetTester tester) async {
    await tester.pumpWidget(const SkinSyncApp());
    await tester.pump(const Duration(milliseconds: 950));

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Skin Profile Setup'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);
  });
}
