import '../data/models/sla_settings.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import 'sla_engine.dart';

/// How much each SLA status is worth when we average them into one number.
/// Completed and On Track are healthy, At Risk is half healthy, Overdue is not.
class HealthScore {
  const HealthScore._();

  static double weightFor(SlaStatus status) {
    switch (status) {
      case SlaStatus.completed:
        return 1.0;
      case SlaStatus.onTrack:
        return 1.0;
      case SlaStatus.atRisk:
        return 0.5;
      case SlaStatus.overdue:
        return 0.0;
    }
  }

  /// 0 to 100. One number a manager can glance at.
  static int compute(
    List<Task> tasks, {
    DateTime? now,
    SlaSettings? settings,
  }) {
    if (tasks.isEmpty) return 100;
    double total = 0;
    for (final Task task in tasks) {
      total += weightFor(
        SlaEngine.evaluate(task, now: now, settings: settings),
      );
    }
    return (100 * total / tasks.length).round();
  }
}
