import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_skinasync/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('auth page shows login form', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SkinSyncApp());
    await tester.pumpAndSettle();

    expect(find.text('SkinSync'), findsWidgets);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
