import 'package:flutter_test/flutter_test.dart';
import 'package:reshmeinfo/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ReshmeInfoApp());
    expect(find.byType(ReshmeInfoApp), findsOneWidget);
  });
}
