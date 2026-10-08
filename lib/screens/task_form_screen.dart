import 'package:flutter/material.dart';

/// OWNER: Gideon. This is a stub - build the real screen in Phase 2.
/// See Roberts-Task-Workout.md for the acceptance criteria.
class TaskFormScreen extends StatelessWidget {
  const TaskFormScreen({super.key, this.taskId});

  /// Passed in through the named route's arguments.
  final String? taskId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: const Center(
        child: Text('Create Task - not built yet (Gideon)'),
      ),
    );
  }
}
