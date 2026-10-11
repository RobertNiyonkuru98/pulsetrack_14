import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pulsetrack/screens/task_form_screen.dart';
import 'package:pulsetrack/state/app_state.dart';

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
    
    // Tap the Create Task button. Two things to handle: the screen also has a
    // "Create Task" header (so target the button, not the bare text), and the
    // button sits below the fold in the default 800x600 test viewport (so scroll
    // to it first - otherwise the tap misses and validation never runs).
    final Finder submit = find.widgetWithText(ElevatedButton, 'Create Task');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    
    // Pump the widget to trigger validation
    await tester.pumpAndSettle();

    // Verify that the validation error is displayed
    expect(find.text('Title is required'), findsOneWidget);
  });
}
