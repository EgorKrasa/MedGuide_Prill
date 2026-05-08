import 'package:flutter_test/flutter_test.dart';

import 'package:prill_mobile/main.dart';

void main() {
  testWidgets('Приложение открывается', (WidgetTester tester) async {
    await tester.pumpWidget(const PrillApp());
    expect(find.text('Клинический справочник'), findsOneWidget);
  });
}
