import 'package:sqflite/sqflite.dart';

import 'models/activity.dart';
import 'models/member.dart';
import 'models/task.dart';

/// Demo data so the app is never empty when we demonstrate it.
/// The dates are relative to "now" on purpose, so the spread of SLA statuses
/// is the same whenever the app is first opened.
class SeedData {
  const SeedData._();

  static List<Member> members() => const <Member>[
        Member(id: 'm1', name: 'John Doe', role: 'Project Manager'),
        Member(id: 'm2', name: 'Sarah Lee', role: 'UI/UX Designer'),
        Member(id: 'm3', name: 'Mike Kim', role: 'Mobile Developer'),
        Member(id: 'm4', name: 'Emily Wong', role: 'QA Tester'),
        Member(id: 'm5', name: 'David Liu', role: 'Technical Writer'),
      ];

  static List<Task> tasks() {
    final DateTime now = DateTime.now();
    return <Task>[
      // On Track
      Task(
        id: 't1',
        title: 'Design Login Screen',
        project: 'UI/UX Design',
        assigneeId: 'm2',
        createdAt: now.subtract(const Duration(days: 6)),
        dueDate: now.add(const Duration(days: 9)),
        priority: Priority.medium,
        status: TaskStatus.inProgress,
        progress: 45,
      ),
      Task(
        id: 't2',
        title: 'Prepare Demo Script',
        project: 'Documentation',
        assigneeId: 'm5',
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 12)),
        priority: Priority.low,
        status: TaskStatus.todo,
        progress: 0,
      ),
      Task(
        id: 't3',
        title: 'Set Up CI Pipeline',
        project: 'DevOps',
        assigneeId: 'm3',
        createdAt: now.subtract(const Duration(days: 10)),
        dueDate: now.add(const Duration(days: 30)),
        priority: Priority.low,
        status: TaskStatus.todo,
        progress: 10,
      ),
      Task(
        id: 't4',
        title: 'Design Dashboard Cards',
        project: 'UI/UX Design',
        assigneeId: 'm2',
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 14)),
        priority: Priority.medium,
        status: TaskStatus.inProgress,
        progress: 20,
      ),

      // At Risk
      Task(
        id: 't5',
        title: 'Implement Local Storage',
        description: 'Wire the sqflite database behind a repository.',
        project: 'Mobile Development',
        assigneeId: 'm3',
        createdAt: now.subtract(const Duration(days: 20)),
        dueDate: now.add(const Duration(days: 2)),
        priority: Priority.high,
        status: TaskStatus.inProgress,
        progress: 60,
      ),
      Task(
        id: 't6',
        title: 'Test Application Flows',
        project: 'Quality Assurance',
        assigneeId: 'm4',
        createdAt: now.subtract(const Duration(days: 3)),
        dueDate: now.add(const Duration(hours: 18)),
        priority: Priority.low,
        status: TaskStatus.todo,
        progress: 0,
      ),
      Task(
        id: 't7',
        title: 'Data Migration Script',
        project: 'Backend (Local)',
        assigneeId: 'm1',
        createdAt: now.subtract(const Duration(days: 12)),
        dueDate: now.add(const Duration(days: 4)),
        priority: Priority.medium,
        status: TaskStatus.inProgress,
        progress: 55,
      ),

      // Overdue
      Task(
        id: 't8',
        title: 'Create Task Model',
        project: 'Backend (Local)',
        assigneeId: 'm1',
        createdAt: now.subtract(const Duration(days: 15)),
        dueDate: now.subtract(const Duration(days: 2)),
        priority: Priority.medium,
        status: TaskStatus.inProgress,
        progress: 70,
      ),
      Task(
        id: 't9',
        title: 'Write Unit Tests',
        project: 'Quality Assurance',
        assigneeId: 'm4',
        createdAt: now.subtract(const Duration(days: 8)),
        dueDate: now.subtract(const Duration(days: 1)),
        priority: Priority.critical,
        status: TaskStatus.todo,
        progress: 0,
      ),

      // Completed
      Task(
        id: 't10',
        title: 'Implement Login Screen',
        project: 'UI/UX Design',
        assigneeId: 'm2',
        createdAt: now.subtract(const Duration(days: 14)),
        dueDate: now.subtract(const Duration(days: 5)),
        priority: Priority.high,
        status: TaskStatus.completed,
        progress: 100,
      ),
    ];
  }

  static List<Activity> activity() {
    final DateTime now = DateTime.now();
    return <Activity>[
      Activity(
        id: 'a1',
        memberId: 'm2',
        message: 'Sarah Lee completed Implement Login Screen',
        at: now.subtract(const Duration(hours: 2)),
        type: ActivityType.completed,
      ),
      Activity(
        id: 'a2',
        memberId: 'm3',
        message: 'Mike Kim changed the status of Implement Local Storage to In Progress',
        at: now.subtract(const Duration(hours: 5)),
        type: ActivityType.statusChanged,
      ),
      Activity(
        id: 'a3',
        memberId: 'm1',
        message: 'John Doe created Create Task Model',
        at: now.subtract(const Duration(days: 1)),
        type: ActivityType.created,
      ),
      Activity(
        id: 'a4',
        memberId: 'm4',
        message: 'Emily Wong was assigned Write Unit Tests',
        at: now.subtract(const Duration(days: 1, hours: 6)),
        type: ActivityType.assigned,
      ),
      Activity(
        id: 'a5',
        memberId: 'm2',
        message: 'Sarah Lee updated Design Login Screen',
        at: now.subtract(const Duration(days: 2)),
        type: ActivityType.updated,
      ),
    ];
  }

  /// Writes the demo data into a freshly created database.
  static Future<void> insertInto(Database db) async {
    final Batch batch = db.batch();

    for (final Member m in members()) {
      batch.insert('members', m.toMap());
    }
    for (final Task t in tasks()) {
      batch.insert('tasks', t.toMap());
    }
    for (final Activity a in activity()) {
      batch.insert('activity', a.toMap());
    }

    await batch.commit(noResult: true);
  }
}
