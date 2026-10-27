import 'package:flutter_test/flutter_test.dart';
import 'package:droidmount/app.dart';

void main() {
  testWidgets('DroidMount app renders main header', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenClawDesktopApp());
    expect(find.text('DroidMount — Android File Manager'), findsOneWidget);
  });
}
