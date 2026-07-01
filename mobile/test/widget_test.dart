import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/providers/task_provider.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(TodalkApp(taskProvider: TaskProvider()));
    expect(find.text('ToDalk'), findsOneWidget);
  });
}
