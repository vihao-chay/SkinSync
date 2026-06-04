import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_skinasync/src/app.dart';

void main() {
  testWidgets('shows SkinSync authentication screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SkinSyncApp());
    await tester.pumpAndSettle();

    expect(find.text('SkinSync'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Đăng ký'), findsWidgets);
  });
}
