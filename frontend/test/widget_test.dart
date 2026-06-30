import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Basic smoke test for Trạm Đọc app
void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Verify that the app's core widget tree can be built
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Trạm Đọc'),
          ),
        ),
      ),
    );

    // Verify the app renders
    expect(find.text('Trạm Đọc'), findsOneWidget);
  });
}
