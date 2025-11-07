import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper to create a widget with provider scope for testing
Widget createTestWidget({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

/// Helper to create a widget with theme for testing
Widget createThemedTestWidget({required Widget child, ThemeData? theme}) {
  return ProviderScope(
    child: MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
    ),
  );
}
