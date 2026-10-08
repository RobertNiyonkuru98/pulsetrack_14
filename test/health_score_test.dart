import 'package:flutter_test/flutter_test.dart';
import 'package:pulsetrack/data/models/task.dart';
import 'package:pulsetrack/logic/health_score.dart';

final DateTime now = DateTime(2026, 1, 15, 12);

Task makeTask({
  required DateTime dueDate,
  DateTime? createdAt,
  Priority priority = Priority.medium,
  TaskStatus status = TaskStatus.todo,
}) =>
    Task(
      id: 't1',
      title: 'Test task',
      assigneeId: 'm1',
      createdAt: createdAt ?? now.subtract(const Duration(days: 1)),
      dueDate: dueDate,
      priority: priority,
      status: status,
    );

void main() {
  group('HealthScore.compute', () {
    test('an empty project scores 100', () {
      expect(HealthScore.compute(<Task>[], now: now), 100);
    });

    test('all tasks completed scores 100', () {
      final List<Task> tasks = List<Task>.generate(
        3,
        (_) => makeTask(
          createdAt: now.subtract(const Duration(days: 7)),
          dueDate: now.subtract(const Duration(days: 1)),
          status: TaskStatus.completed,
        ),
      );
      expect(HealthScore.compute(tasks, now: now), 100);
    });

    test('every task overdue scores 0', () {
      final List<Task> tasks = List<Task>.generate(
        3,
        (_) => makeTask(
          createdAt: now.subtract(const Duration(days: 10)),
          dueDate: now.subtract(const Duration(days: 1)),
        ),
      );
      expect(HealthScore.compute(tasks, now: now), 0);
    });

    test('an At Risk task is worth half a healthy one', () {
      final List<Task> tasks = <Task>[
        makeTask(
          createdAt: now.subtract(const Duration(days: 8)),
          dueDate: now.add(const Duration(days: 2)),
        ),
      ];
      expect(HealthScore.compute(tasks, now: now), 50);
    });

    test('a mixed project averages the weights', () {
      final List<Task> tasks = <Task>[
        makeTask(
          createdAt: now.subtract(const Duration(days: 5)),
          dueDate: now.subtract(const Duration(days: 1)),
          status: TaskStatus.completed,
        ), // 1.0
        makeTask(
          createdAt: now.subtract(const Duration(days: 1)),
          dueDate: now.add(const Duration(days: 9)),
        ), // 1.0
        makeTask(
          createdAt: now.subtract(const Duration(days: 5)),
          dueDate: now.subtract(const Duration(days: 2)),
        ), // 0.0
        makeTask(
          createdAt: now.subtract(const Duration(days: 5)),
          dueDate: now.subtract(const Duration(days: 3)),
        ), // 0.0
      ];
      // (1 + 1 + 0 + 0) / 4 = 0.5  ->  50
      expect(HealthScore.compute(tasks, now: now), 50);
    });
  });
}
