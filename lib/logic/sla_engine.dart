import '../data/models/sla_settings.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';

/// PulseTrack's SLA engine.
///
/// This is the business logic the assignment asks us to be able to explain:
/// a task's deadline plus its completion state produce one of four statuses.
///
/// The rules are evaluated from the TOP DOWN and the FIRST match wins, so the
/// order below is the rule. Do not reorder them.
class SlaEngine {
  const SlaEngine._();

  /// The share of the allotted window that must still be left before a task is
  /// called At Risk. Higher priority means we warn earlier.
  static double thresholdFor(Priority priority, SlaSettings settings) {
    switch (priority) {
      case Priority.critical:
        return settings.criticalThreshold;
      case Priority.high:
        return settings.highThreshold;
      case Priority.medium:
        return settings.mediumThreshold;
      case Priority.low:
        return settings.lowThreshold;
    }
  }

  /// The whole engine, in six lines of rules.
  static SlaStatus evaluate(
    Task task, {
    DateTime? now,
    SlaSettings? settings,
  }) {
    final DateTime moment = now ?? DateTime.now();
    final SlaSettings s = settings ?? const SlaSettings();

    // 1. Finished work is always Completed, even if the date has passed.
    if (task.status == TaskStatus.completed) {
      return SlaStatus.completed;
    }

    // 2. Blocked work cannot make progress, so we escalate it immediately.
    if (s.flagBlockedAsAtRisk && task.status == TaskStatus.blocked) {
      return SlaStatus.atRisk;
    }

    // 3. The deadline has already gone by.
    if (moment.isAfter(task.dueDate)) {
      return SlaStatus.overdue;
    }

    final Duration remaining = task.dueDate.difference(moment);

    // 4. Hard safety net: under 24 hours left is always At Risk.
    if (s.warnUnder24h && remaining.inMinutes <= 24 * 60) {
      return SlaStatus.atRisk;
    }

    // 5. Proportional rule: how much of the window is left, versus the
    //    threshold our priority deserves.
    final int totalMinutes =
        task.dueDate.difference(task.createdAt).inMinutes;
    if (totalMinutes > 0) {
      final double remainingFraction = remaining.inMinutes / totalMinutes;
      if (remainingFraction <= thresholdFor(task.priority, s)) {
        return SlaStatus.atRisk;
      }
    }

    // 6. Nothing above matched, so the task is fine.
    return SlaStatus.onTrack;
  }

  /// One sentence explaining WHY the status came out the way it did.
  /// The Task Details screen prints this, so the user never has to guess.
  static String explain(
    Task task, {
    DateTime? now,
    SlaSettings? settings,
  }) {
    final DateTime moment = now ?? DateTime.now();
    final SlaSettings s = settings ?? const SlaSettings();
    final SlaStatus status = evaluate(task, now: moment, settings: s);

    switch (status) {
      case SlaStatus.completed:
        return 'This task is finished, so it counts as Completed.';

      case SlaStatus.overdue:
        final int late = moment.difference(task.dueDate).inDays;
        return 'The deadline passed ${late == 0 ? 'today' : '$late day(s) ago'} '
            'and the task is still open, so it is Overdue.';

      case SlaStatus.atRisk:
        if (s.flagBlockedAsAtRisk && task.status == TaskStatus.blocked) {
          return 'The task is blocked. Blocked work cannot progress, so we '
              'escalate it to At Risk.';
        }
        final Duration remaining = task.dueDate.difference(moment);
        if (s.warnUnder24h && remaining.inMinutes <= 24 * 60) {
          return 'Less than 24 hours remain, which is our hard safety net, '
              'so it is At Risk.';
        }
        final double elapsed = elapsedPercent(task, moment);
        return '${(elapsed * 100).round()}% of the allotted window has already '
            'elapsed and only ${((1 - elapsed) * 100).round()}% is left, below '
            'the ${(thresholdFor(task.priority, s) * 100).round()}% we allow a '
            '${task.priority.label} priority task.';

      case SlaStatus.onTrack:
        final double elapsed = elapsedPercent(task, moment);
        return 'The task is progressing as expected: '
            '${(elapsed * 100).round()}% of the allotted window has elapsed.';
    }
  }

  /// 0.0 = just created, 1.0 = deadline reached. Clamped so bad data cannot
  /// produce a nonsense percentage on screen.
  static double elapsedPercent(Task task, DateTime moment) {
    final int total = task.dueDate.difference(task.createdAt).inMinutes;
    if (total <= 0) return 1;
    final double value =
        moment.difference(task.createdAt).inMinutes / total;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  /// "3 days", "5 hours" - used by the Task Details SLA panel.
  static String humanRemaining(DateTime dueDate, DateTime moment) {
    final Duration d = dueDate.difference(moment);
    if (d.isNegative) return 'past due';
    if (d.inDays >= 1) return '${d.inDays} day(s)';
    if (d.inHours >= 1) return '${d.inHours} hour(s)';
    return '${d.inMinutes} minute(s)';
  }
}
