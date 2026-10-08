import 'package:flutter/material.dart';

/// OWNER: Gideon. This is a stub - build the real screen in Phase 2.
/// See Roberts-Task-Workout.md for the acceptance criteria.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, this.taskId});

  /// Passed in through the named route's arguments.
  final String? taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: const Center(
        child: Text('Task Details - not built yet (Gideon)'),
      ),
    );
  }
}
