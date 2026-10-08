import 'package:flutter/material.dart';

/// OWNER: Admire. This is a stub - build the real screen in Phase 2.
/// See Roberts-Task-Workout.md for the acceptance criteria.
class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({super.key, this.memberId});

  /// Passed in through the named route's arguments.
  final String? memberId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member')),
      body: const Center(
        child: Text('Member - not built yet (Admire)'),
      ),
    );
  }
}
