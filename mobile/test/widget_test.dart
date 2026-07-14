import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/task_provider.dart';
import 'package:mobile/services/api_service.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/flutter_secure_storage'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
          case 'readAll':
            return null;
          case 'write':
          case 'deleteAll':
          case 'delete':
            return null;
          case 'containsKey':
            return false;
          default:
            return null;
        }
      },
    );

    final apiService = ApiService(baseUrl: 'http://localhost:3000');
    await apiService.init();
    final authProvider = AuthProvider(apiService: apiService);
    final taskProvider = TaskProvider(apiService: apiService);

    await tester.pumpWidget(TodalkApp(
      taskProvider: taskProvider,
      authProvider: authProvider,
      initialRoute: '/auth',
    ));
    expect(find.text('ToDalk'), findsOneWidget);
  });
}
