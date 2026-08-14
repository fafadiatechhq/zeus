import 'package:flutter_test/flutter_test.dart';
import 'package:zeus/main.dart';

void main() {
  testWidgets('Zeus app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZeusApp());
    expect(find.text('Zeus'), findsWidgets);
  });
}
