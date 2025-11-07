import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pomodojo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App launches and shows login screen when unauthenticated', (
      WidgetTester tester,
    ) async {
      app.main();

      // Allow time for Firebase init and first frame
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // The login screen contains the PomoDojo title and Login Account heading
      expect(find.text('PomoDojo'), findsWidgets);
      expect(find.text('Login Account'), findsOneWidget);
    });

    testWidgets('App launches successfully', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify app has launched (check for any key widget that should be present)
      // Since we don't know if user is logged in, we check for MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
