import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pulsetrack_14/screens/task_form_screen.dart';
import 'package:pulsetrack_14/state/app_state.dart';

void main() {
  testWidgets('TaskFormScreen shows validation error when title is empty', (WidgetTester tester) async {
    // Create a mock AppState
    final appState = AppState();
    
    // Build the widget
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: TaskFormScreen(),
        ),
      ),
    );

    // Verify initially no validation error
    expect(find.text('Title is required'), findsNothing);

    // Clear the title field (it should be empty by default anyway)
    await tester.enterText(find.byType(TextFormField).first, '');
    
    // Tap the Create Task button
    await tester.tap(find.text('Create Task'));
    
    // Pump the widget to trigger validation
    await tester.pumpAndSettle();

    // Verify that the validation error is displayed
    expect(find.text('Title is required'), findsOneWidget);
  });
}
