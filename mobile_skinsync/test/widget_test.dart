import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_skinasync/app.dart';

void main() {
  testWidgets('landing page shows primary CTA', (WidgetTester tester) async {
    await tester.pumpWidget(const SkinSyncApp());
    await tester.pumpAndSettle();

    expect(find.text('Start Skin Quiz'), findsWidgets);
    expect(find.text('SkinSync'), findsWidgets);
  });
}
