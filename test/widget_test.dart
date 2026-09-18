import 'package:flutter_test/flutter_test.dart';
import 'package:saahat_app/main.dart';

void main() {
  testWidgets('Saahat app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SaahatApp());
    expect(find.text('Saahat — Setup Successful'), findsOneWidget);
  });
}
