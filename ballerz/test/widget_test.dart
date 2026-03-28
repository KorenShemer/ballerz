import 'package:flutter_test/flutter_test.dart';
import 'package:ballerz/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FootballApp());
    expect(find.byType(FootballApp), findsOneWidget);
  });
}