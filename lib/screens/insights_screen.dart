import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/member.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/sla_badge.dart';

/// Screen 9 - Insights. OWNER: Robert.
///
/// The Dashboard answers "what is happening?". This screen answers "who and
/// what is slipping?". Three things, in the order a manager asks them:
///
///   1. the status breakdown, as a bar chart colour-matched to the badges;
///   2. the SLA breach leaderboard - who is carrying the overdue work;
///   3. the five deadlines coming up next.
///
/// There is no Figma frame for this screen, so it is built from the same tokens
/// as the Dashboard: the violet, the warm page, the white cards.
///
/// Every number comes from [AppState] - the same source the Dashboard reads, so
/// the two screens cannot disagree. That agreement is asserted in the tests.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int onTrack = state.countOf(SlaStatus.onTrack);
    final int atRisk = state.countOf(SlaStatus.atRisk);
    final int overdue = state.countOf(SlaStatus.overdue);
    final int completed = state.countOf(SlaStatus.completed);
    final int total = state.tasks.length;
    final int needsAttention = atRisk + overdue;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Insights')),
      body: total == 0
          ? const _NothingYet()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: <Widget>[
                Text(
                  '$total tasks  ·  $needsAttention need attention',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 18),

                _Card(
                  title: 'Status breakdown',
                  caption: 'Every task, by SLA status. Matches the Dashboard.',
                  child: _StatusChart(
                    onTrack: onTrack,
                    atRisk: atRisk,
                    overdue: overdue,
                    completed: completed,
                  ),
                ),
                const SizedBox(height: 16),

                _Card(
                  title: 'SLA breach leaderboard',
                  caption: 'Who is carrying the overdue work.',
                  child: _Leaderboard(state: state),
                ),
                const SizedBox(height: 16),

                _Card(
                  title: 'Upcoming deadlines',
                  caption: 'The five open tasks due soonest.',
                  child: _Deadlines(state: state),
                ),
              ],
            ),
    );
  }
}

/// Shown when there is genuinely nothing to look at.
class _NothingYet extends StatelessWidget {
  const _NothingYet();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No tasks yet. Create one and the insight appears here.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.muted),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ status chart

class _StatusChart extends StatelessWidget {
  const _StatusChart({
    required this.onTrack,
    required this.atRisk,
    required this.overdue,
    required this.completed,
  });

  final int onTrack;
  final int atRisk;
  final int overdue;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final List<_Bar> bars = <_Bar>[
      _Bar('On Track', onTrack, AppColors.onTrackFill),
      _Bar('At Risk', atRisk, AppColors.atRiskFill),
      _Bar('Overdue', overdue, AppColors.overdueFill),
      _Bar('Completed', completed, AppColors.completedFill),
    ];
    final int highest = bars
        .map((_Bar b) => b.value)
        .reduce((int a, int b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars
          .map((_Bar b) => Expanded(child: _BarColumn(bar: b, highest: highest)))
          .toList(),
    );
  }
}

class _Bar {
  const _Bar(this.label, this.value, this.fill);

  final String label;
  final int value;
  final Color fill;
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({required this.bar, required this.highest});

  final _Bar bar;
  final int highest;

  /// The height of the tallest bar. The others scale against it, so the shape
  /// of the chart is the same whether the project has 4 tasks or 400.
  static const double _chartHeight = 120;

  @override
  Widget build(BuildContext context) {
    final double height = highest <= 0
        ? 6
        : math.max(6, _chartHeight * bar.value / highest);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '${bar.value}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        // The pale track shows the full scale; the coloured bar shows the value.
        Container(
          width: 26,
          height: _chartHeight,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: height,
              decoration: BoxDecoration(
                color: bar.fill,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          bar.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- leaderboard

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final List<_Breach> rows = <_Breach>[];
    for (final Member m in state.members) {
      final List<Task> mine = state.tasksFor(m.id);
      int overdue = 0;
      int atRisk = 0;
      for (final Task t in mine) {
        final SlaStatus s = state.statusOf(t);
        if (s == SlaStatus.overdue) overdue++;
        if (s == SlaStatus.atRisk) atRisk++;
      }
      rows.add(_Breach(m, overdue, atRisk, mine.length));
    }

    // Worst offender first, then busiest - a tie-break that is still meaningful.
    rows.sort((_Breach a, _Breach b) {
      final int byOverdue = b.overdue.compareTo(a.overdue);
      return byOverdue != 0 ? byOverdue : b.assigned.compareTo(a.assigned);
    });

    final int worst = rows.isEmpty
        ? 0
        : rows.map((_Breach r) => r.overdue).reduce((int a, int b) => a > b ? a : b);

    if (rows.isEmpty) {
      return const Text(
        'No members to rank yet.',
        style: TextStyle(fontSize: 13, color: AppColors.muted),
      );
    }

    if (worst == 0) {
      return const Row(
        children: <Widget>[
          Icon(Icons.verified_outlined, size: 18, color: AppColors.onTrack),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nobody has breached an SLA. Every open task is still On Track '
              'or At Risk.',
              style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      );
    }

    return Column(
      children: rows
          .map((_Breach r) => _BreachRow(breach: r, worst: worst))
          .toList(),
    );
  }
}

class _Breach {
  const _Breach(this.member, this.overdue, this.atRisk, this.assigned);

  final Member member;
  final int overdue;
  final int atRisk;
  final int assigned;
}

class _BreachRow extends StatelessWidget {
  const _BreachRow({required this.breach, required this.worst});

  final _Breach breach;
  final int worst;

  @override
  Widget build(BuildContext context) {
    final double fraction = worst <= 0 ? 0 : breach.overdue / worst;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              breach.member.initials,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  breach.member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 7,
                    color: AppColors.border,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: Container(color: AppColors.overdueFill),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${breach.overdue}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: breach.overdue == 0
                  ? AppColors.muted
                  : AppColors.overdueInk,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- deadlines

class _Deadlines extends StatelessWidget {
  const _Deadlines({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final List<Task> soonest = state.tasks
        .where((Task t) => state.statusOf(t) != SlaStatus.completed)
        .toList()
      ..sort((Task a, Task b) => a.dueDate.compareTo(b.dueDate));

    if (soonest.isEmpty) {
      return const Text(
        'Nothing open. Every task is done.',
        style: TextStyle(fontSize: 13, color: AppColors.muted),
      );
    }

    return Column(
      children: soonest
          .take(5)
          .map((Task t) => _DeadlineRow(task: t, state: state))
          .toList(),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.task, required this.state});

  final Task task;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.taskDetails,
        arguments: task.id,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${task.project}  ·  due ${DateFormat('d MMM, h:mm a').format(task.dueDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SlaBadge(status: state.statusOf(task)),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- small parts

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.caption});

  final String title;
  final Widget child;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
