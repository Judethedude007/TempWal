import 'package:flutter_test/flutter_test.dart';
import 'package:tempwal/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TempWalApp());
    expect(find.text('TempWal'), findsOneWidget);
  });
}
