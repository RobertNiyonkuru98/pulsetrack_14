import 'package:flutter_test/flutter_test.dart';
import 'package:pulsetrack/data/models/sla_settings.dart';
import 'package:pulsetrack/data/models/sla_status.dart';
import 'package:pulsetrack/data/models/task.dart';
import 'package:pulsetrack/logic/sla_engine.dart';

/// A fixed "now" so these tests never depend on the machine clock.
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
  group('SlaEngine.evaluate - rule order (first match wins)', () {
    test('a completed task is Completed even when its deadline has passed', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 7)),
        dueDate: now.subtract(const Duration(days: 5)),
        status: TaskStatus.completed,
      );
      expect(SlaEngine.evaluate(t, now: now), SlaStatus.completed);
    });

    test('a blocked task is escalated to At Risk', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 30)),
        status: TaskStatus.blocked,
      );
      expect(SlaEngine.evaluate(t, now: now), SlaStatus.atRisk);
    });

    test('an open task past its deadline is Overdue', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.subtract(const Duration(days: 2)),
      );
      expect(SlaEngine.evaluate(t, now: now), SlaStatus.overdue);
    });

    test('under 24 hours left is At Risk, via the hard safety net', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(hours: 12)),
      );
      expect(SlaEngine.evaluate(t, now: now), SlaStatus.atRisk);
    });

    test('plenty of time left is On Track', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 9)),
      );
      expect(SlaEngine.evaluate(t, now: now), SlaStatus.onTrack);
    });
  });

  group('SlaEngine.evaluate - the proportional rule', () {
    test('20% of a 10-day window left is At Risk for a Medium task', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 8)),
        dueDate: now.add(const Duration(days: 2)),
      );
      expect(SlaEngine.evaluate(t, now: now), SlaStatus.atRisk);
    });

    test('the same 35%-left task differs by priority - this is the weighting', () {
      // 3.5 days left out of a 10 day window = 35% remaining.
      final DateTime due = now.add(const Duration(hours: 84));
      final DateTime created = due.subtract(const Duration(days: 10));

      final Task high = makeTask(
        createdAt: created, dueDate: due, priority: Priority.high);
      final Task low = makeTask(
        createdAt: created, dueDate: due, priority: Priority.low);

      // High allows 40%, so 35% left is already At Risk.
      expect(SlaEngine.evaluate(high, now: now), SlaStatus.atRisk);
      // Low allows only 20%, so 35% left is still On Track.
      expect(SlaEngine.evaluate(low, now: now), SlaStatus.onTrack);
    });
  });

  group('SlaEngine.evaluate - the rules are configurable', () {
    test('blocked tasks stop being escalated when the toggle is off', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.add(const Duration(days: 30)),
        status: TaskStatus.blocked,
      );
      expect(
        SlaEngine.evaluate(
          t,
          now: now,
          settings: const SlaSettings(flagBlockedAsAtRisk: false),
        ),
        SlaStatus.onTrack,
      );
    });

    test('the 24-hour safety net can be turned off', () {
      final Task t = makeTask(
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(hours: 12)),
      );
      expect(
        SlaEngine.evaluate(
          t,
          now: now,
          settings: const SlaSettings(warnUnder24h: false),
        ),
        SlaStatus.onTrack,
      );
    });
  });

  group('SlaEngine.explain', () {
    test('every status produces a sentence naming the rule that applied', () {
      final Task onTrack = makeTask(
        createdAt: now.subtract(const Duration(days: 1)),
        dueDate: now.add(const Duration(days: 9)),
      );
      expect(SlaEngine.explain(onTrack, now: now), contains('elapsed'));

      final Task overdue = makeTask(
        createdAt: now.subtract(const Duration(days: 5)),
        dueDate: now.subtract(const Duration(days: 3)),
      );
      expect(SlaEngine.explain(overdue, now: now), contains('Overdue'));

      final Task completed = makeTask(
        createdAt: now.subtract(const Duration(days: 7)),
        dueDate: now.subtract(const Duration(days: 3)),
        status: TaskStatus.completed,
      );
      expect(SlaEngine.explain(completed, now: now), contains('Completed'));
    });
  });
}
