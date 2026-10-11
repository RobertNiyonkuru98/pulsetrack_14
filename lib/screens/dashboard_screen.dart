import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/models/activity.dart';
import '../data/models/member.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/donut_chart.dart';

/// Screen 2 - the Dashboard.
///
/// Rebuilt to the group's Figma design: a violet KPI grid, the "next task"
/// card, Project Health, Task Overview and Recent Activity, sitting on a warm
/// off-white page above the floating dark navigation bar.
///
/// It is still the reference screen for the team. Every number on it comes from
/// [AppState] - the screen never touches the database or the SLA engine itself.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int total = state.tasks.length;
    final int onTrack = state.countOf(SlaStatus.onTrack);
    final int atRisk = state.countOf(SlaStatus.atRisk);
    final int overdue = state.countOf(SlaStatus.overdue);
    final int completed = state.countOf(SlaStatus.completed);

    // Open tasks whose deadline falls before midnight tonight.
    final int dueToday = state.tasks.where((Task t) {
      return _isToday(t.dueDate) && state.statusOf(t) != SlaStatus.completed;
    }).length;

    // "Next Task" is the most urgent open task. When nothing has been flagged
    // yet we fall back to the soonest deadline, so the card is never empty
    // while there is work outstanding. Its position in the queue is the
    // "PRIORITY n" label the design puts in the corner.
    final List<Task> attention = state.attentionQueue;
    final List<Task> open = state.tasks
        .where((Task t) => state.statusOf(t) != SlaStatus.completed)
        .toList()
      ..sort((Task a, Task b) => a.dueDate.compareTo(b.dueDate));
    final Task? nextTask = attention.isNotEmpty
        ? attention.first
        : (open.isEmpty ? null : open.first);
    final int nextRank =
        attention.isEmpty ? 1 : attention.indexOf(nextTask!) + 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: _TopBar(state: state),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: <Widget>[
                  _GreetingRow(state: state),

                  const SizedBox(height: 22),
                  _Headline(count: dueToday),

                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _KpiTile(
                          label: 'Total Tasks',
                          value: '$total',
                          fill: AppColors.primary,
                          ink: AppColors.onPrimary,
                          icon: Icons.format_list_bulleted_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _KpiTile(
                          label: 'On Track',
                          value: '$onTrack',
                          fill: AppColors.onTrackFill,
                          ink: AppColors.onTrackInk,
                          icon: Icons.check_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _KpiTile(
                          label: 'At Risk',
                          value: '$atRisk',
                          fill: AppColors.atRiskFill,
                          ink: AppColors.atRiskInk,
                          icon: Icons.warning_amber_rounded,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _KpiTile(
                          label: 'Overdue',
                          value: '$overdue',
                          fill: AppColors.overdueFill,
                          ink: AppColors.overdueInk,
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),
                  _MembersRow(state: state),

                  if (nextTask != null) ...<Widget>[
                    const SizedBox(height: 26),
                    _NextTaskCard(
                      task: nextTask,
                      state: state,
                      rank: nextRank,
                    ),
                  ],

                  const SizedBox(height: 22),
                  _HealthCard(score: state.healthScore, taskCount: total),

                  const SizedBox(height: 20),
                  _OverviewCard(
                    total: total,
                    onTrack: onTrack,
                    atRisk: atRisk,
                    overdue: overdue,
                    completed: completed,
                  ),

                  const SizedBox(height: 26),
                  _RecentActivity(state: state),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  static bool _isToday(DateTime date) {
    final DateTime now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// ---------------------------------------------------------------- top bar

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bar_chart_rounded,
            size: 22,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        _CircleButton(
          icon: Icons.search_rounded,
          onTap: () => Navigator.pushNamed(context, Routes.tasks),
        ),
        const SizedBox(width: 10),
        _Avatar(
          member: state.currentUser,
          radius: 20,
          onTap: () => Navigator.pushNamed(context, Routes.profile),
        ),
      ],
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _Avatar(member: state.currentUser, radius: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _greeting(),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                state.currentUser?.name ?? 'Guest',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        _BellButton(showDot: state.attentionQueue.isNotEmpty),
      ],
    );
  }

  static String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.showDot});

  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        _CircleButton(
          icon: Icons.notifications_none_rounded,
          onTap: () => Navigator.pushNamed(context, Routes.activity),
        ),
        if (showDot)
          const Positioned(
            right: 7,
            top: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 10, height: 10),
            ),
          ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 26, height: 1.18),
        children: <TextSpan>[
          TextSpan(
            text: 'You have $count\n',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const TextSpan(
            text: 'tasks due today',
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- KPI tiles

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.fill,
    required this.ink,
    required this.icon,
  });

  final String label;
  final String value;
  final Color fill;
  final Color ink;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, size: 17, color: ink)),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            value,
            style: TextStyle(
              fontSize: 38,
              height: 1.0,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- members row

class _MembersRow extends StatelessWidget {
  const _MembersRow({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final List<Member> members = state.members;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${members.length} Members',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            _CircleButton(
              icon: Icons.add_rounded,
              background: AppColors.primarySoft,
              foreground: AppColors.primaryDark,
              onTap: () => Navigator.pushNamed(context, Routes.team),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _AvatarStack(members: members),
      ],
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Text(
        'No members yet',
        style: TextStyle(fontSize: 13, color: AppColors.muted),
      );
    }

    const double step = 28;
    final int shown = members.length > 4 ? 4 : members.length;
    final int extra = members.length - shown;
    final double width = shown * step + (extra > 0 ? 44 : 16);

    return SizedBox(
      width: width,
      height: 44,
      child: Stack(
        children: <Widget>[
          for (int i = 0; i < shown; i++)
            Positioned(
              left: i * step,
              top: 0,
              child: _Avatar(member: members[i], radius: 22, ring: true),
            ),
          if (extra > 0)
            Positioned(
              left: shown * step,
              top: 0,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------ next task

class _NextTaskCard extends StatelessWidget {
  const _NextTaskCard({
    required this.task,
    required this.state,
    required this.rank,
  });

  final Task task;
  final AppState state;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final SlaStatus status = state.statusOf(task);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Next Task',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            Text(
              'PRIORITY $rank',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => Navigator.pushNamed(
              context,
              Routes.taskDetails,
              arguments: task.id,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _StatusChip(status: status),
                      const Spacer(),
                      _Avatar(
                        member: state.memberById(task.assigneeId),
                        radius: 16,
                        ring: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    task.project,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xE6FFFFFF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dueLabel(task.dueDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xE6FFFFFF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _ArrowButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _dueLabel(DateTime due) {
    final DateTime now = DateTime.now();
    final String time = DateFormat('h:mm a').format(due);
    final bool today = due.year == now.year &&
        due.month == now.month &&
        due.day == now.day;
    return today
        ? 'Due today, $time'
        : 'Due ${DateFormat('d MMM').format(due)}, $time';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SlaStatus status;

  @override
  Widget build(BuildContext context) {
    final Color fill = switch (status) {
      SlaStatus.onTrack => AppColors.onTrackFill,
      SlaStatus.atRisk => AppColors.atRiskFill,
      SlaStatus.overdue => AppColors.overdueFill,
      SlaStatus.completed => AppColors.completedFill,
    };
    final Color ink = switch (status) {
      SlaStatus.onTrack => AppColors.onTrackInk,
      SlaStatus.atRisk => AppColors.atRiskInk,
      SlaStatus.overdue => AppColors.overdueInk,
      SlaStatus.completed => AppColors.completedInk,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        size: 20,
        color: AppColors.ink,
      ),
    );
  }
}

// -------------------------------------------------------- project health

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.score, required this.taskCount});

  final int score;
  final int taskCount;

  @override
  Widget build(BuildContext context) {
    final bool good = score >= 75;
    final bool mid = score >= 45;
    final String label = good ? 'Optimal' : (mid ? 'Needs Attention' : 'At Risk');
    final Color fg =
        good ? AppColors.onTrack : (mid ? AppColors.atRisk : AppColors.overdue);
    final Color bg = good
        ? AppColors.onTrackSoft
        : (mid ? AppColors.atRiskSoft : AppColors.overdueSoft);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Project Health',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              _Pill(text: label, bg: bg, fg: fg),
            ],
          ),
          const SizedBox(height: 18),
          _HealthRing(score: score),
          const SizedBox(height: 14),
          Text(
            'Based on the SLA status of $taskCount tasks',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.score});

  final int score;

  /// Diameter in logical pixels - big enough for "78%" to read clearly.
  static const double _diameter = 150;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _diameter,
      height: _diameter,
      child: CustomPaint(
        painter: _HealthRingPainter(progress: score / 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$score%',
                style: TextStyle(
                  fontSize: _diameter * 0.24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                'Health Score',
                style: TextStyle(
                  fontSize: _diameter * 0.078,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  _HealthRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.width * 0.085;
    final Rect rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final Paint track = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final Paint bar = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: <Color>[
          AppColors.overdueFill,
          AppColors.atRiskFill,
          AppColors.onTrackFill,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthRingPainter old) =>
      old.progress != progress;
}

// --------------------------------------------------------- task overview

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.total,
    required this.onTrack,
    required this.atRisk,
    required this.overdue,
    required this.completed,
  });

  final int total;
  final int onTrack;
  final int atRisk;
  final int overdue;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Task Overview',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '$total active',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              DonutChart(
                size: 132,
                centerLabel: 'Tasks',
                slices: <DonutSlice>[
                  DonutSlice(
                    value: onTrack.toDouble(),
                    color: AppColors.onTrackFill,
                    label: 'On Track',
                  ),
                  DonutSlice(
                    value: atRisk.toDouble(),
                    color: AppColors.atRiskFill,
                    label: 'At Risk',
                  ),
                  DonutSlice(
                    value: overdue.toDouble(),
                    color: AppColors.overdueFill,
                    label: 'Overdue',
                  ),
                  DonutSlice(
                    value: completed.toDouble(),
                    color: AppColors.completedFill,
                    label: 'Completed',
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: <Widget>[
                    _LegendRow(
                      color: AppColors.onTrackFill,
                      label: 'On Track',
                      value: onTrack,
                    ),
                    _LegendRow(
                      color: AppColors.atRiskFill,
                      label: 'At Risk',
                      value: atRisk,
                    ),
                    _LegendRow(
                      color: AppColors.overdueFill,
                      label: 'Overdue',
                      value: overdue,
                    ),
                    _LegendRow(
                      color: AppColors.completedFill,
                      label: 'Completed',
                      value: completed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.ink),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------- recent activity

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final List<Activity> recent = state.activity.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pushNamed(context, Routes.activity),
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No activity yet.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          )
        else
          ...recent.map(
            (Activity a) => _ActivityRow(activity: a, state: state),
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity, required this.state});

  final Activity activity;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final Member? member = state.memberById(activity.memberId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          _Avatar(member: member, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member?.role ?? 'Team member',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _relative(activity.at),
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  static String _relative(DateTime at) {
    final Duration d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'Yesterday';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return DateFormat('d MMM').format(at);
  }
}

// --------------------------------------------------------- shared pieces

/// A circular white icon button - the search and bell in the header, and the
/// "+" next to the member list (which tints it lavender instead).
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onTap,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: Icon(icon, size: 20, color: foreground)),
        ),
      ),
    );
  }
}

/// Initials avatar. The design uses photographs, but we ship no image assets,
/// so we draw the member's initials on the lavender wash instead.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.member,
    this.radius = 22,
    this.ring = false,
    this.onTap,
  });

  final Member? member;
  final double radius;
  final bool ring;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget circle = Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: AppColors.surface, width: 2) : null,
      ),
      child: Text(
        member?.initials ?? '?',
        style: TextStyle(
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );

    if (onTap == null) return circle;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: circle,
    );
  }
}
