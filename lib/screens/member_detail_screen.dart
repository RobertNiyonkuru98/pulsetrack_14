import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/activity.dart';
import '../data/models/member.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/sla_badge.dart';

/// Member Detail. OWNER: Admire.
///
/// Opened from the Team Members screen (Routes.memberDetail, arguments = the
/// member id). Shows who the member,the SLA health of their tasks, their task list, and their slice
/// of the activity trail.
///
class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({super.key, this.memberId});

  /// Passed in through the named route's arguments.
  final String? memberId;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Member? member = state.memberById(memberId ?? '');
    if (member == null) {
      return _notFound();
    }

    // Everything this screen needs, in three plain variables.
    final List<Task> tasks = state.tasksFor(member.id);
    final List<Activity> trail = state.activity
        .where((Activity a) => a.memberId == member.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(member.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeaderCard(member: member),
          _gap(16),
          _section(
            title: 'SLA Overview',
            child: _StatusRow(state: state, tasks: tasks),
          ),
          _gap(16),
          _section(
            title: 'Tasks (${tasks.length})',
            child: tasks.isEmpty
                ? const _MutedText('No tasks assigned to this member yet.')
                : Column(children: _taskRows(context, state, tasks)),
          ),
          _gap(16),
          _section(
            title: 'Recent Activity',
            child: trail.isEmpty
                ? const _MutedText(
                    'Nothing yet. Actions by this member appear here.',
                  )
                : Column(
                    children: <Widget>[
                      for (final Activity a in trail.take(5)) _TrailRow(activity: a),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================== build pieces

  Scaffold _notFound() {
    return Scaffold(
      appBar: AppBar(title: const Text('Member')),
      body: const EmptyState(
        icon: Icons.person_off_outlined,
        title: 'Member not found',
        message: 'This member may have been removed from the team.',
      ),
    );
  }

  List<Widget> _taskRows(
    BuildContext context,
    AppState state,
    List<Task> tasks,
  ) {
    return <Widget>[
      for (final Task t in tasks)
        _TaskRow(
          task: t,
          status: state.statusOf(t),
          onTap: () => Navigator.pushNamed(
            context,
            Routes.taskDetails,
            arguments: t.id,
          ),
        ),
    ];
  }
}

// ================================================================ file helpers

Widget _gap([double height = 16]) => SizedBox(height: height);

/// "just now", "5m ago", "2h ago", "3d ago", then a short date.
String _timeAgo(DateTime at) {
  final Duration d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${at.day}/${at.month}/${at.year}';
}

/// Same section-card pattern the Dashboard uses
Widget _section({required String title, required Widget child}) {
  final Widget heading = Text(
    title,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
  );

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: AppTheme.cardDecoration,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[heading, _gap(12), child],
    ),
  );
}

/// One quiet grey line, used wherever a section has nothing to show.
class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
    );
  }
}

// ================================================================ the widgets

/// User Avatar, name, role, email
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.primary,
      child: Text(
        member.initials,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    final Widget who = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(member.role, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          if (member.email.isNotEmpty)
            Text(member.email, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Row(children: <Widget>[avatar, _gap(14), who]),
    );
  }
}

/// The four SLA counts, colour-coded like every other SLA surface.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.state, required this.tasks});

  final AppState state;
  final List<Task> tasks;

  @override
  Widget build(BuildContext context) {
    // Count each task once, straight from the SLA engine.
    final Map<SlaStatus, int> counts = <SlaStatus, int>{
      for (final SlaStatus s in SlaStatus.values) s: 0,
    };
    for (final Task t in tasks) {
      counts[state.statusOf(t)] = counts[state.statusOf(t)]! + 1;
    }

    return Row(
      children: <Widget>[
        _StatusPill(
          label: 'On Track',
          value: counts[SlaStatus.onTrack]!,
          color: AppColors.onTrack,
          soft: AppColors.onTrackSoft,
        ),
        _gap(8),
        _StatusPill(
          label: 'At Risk',
          value: counts[SlaStatus.atRisk]!,
          color: AppColors.atRisk,
          soft: AppColors.atRiskSoft,
        ),
        _gap(8),
        _StatusPill(
          label: 'Overdue',
          value: counts[SlaStatus.overdue]!,
          color: AppColors.overdue,
          soft: AppColors.overdueSoft,
        ),
        _gap(8),
        _StatusPill(
          label: 'Done',
          value: counts[SlaStatus.completed]!,
          color: AppColors.completed,
          soft: AppColors.completedSoft,
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.value,
    required this.color,
    required this.soft,
  });

  final String label;
  final int value;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    final Widget number = Text(
      '$value',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
    );

    final Widget caption = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
    );

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(10)),
        child: Column(children: <Widget>[number, const SizedBox(height: 2), caption]),
      ),
    );
  }
}

/// One task of this member: title, SLA badge, due date, progress.
class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.status,
    required this.onTap,
  });

  final Task task;
  final SlaStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String due = 'due '
        '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}';

    final Widget titleRow = Row(
      children: <Widget>[
        Expanded(
          child: Text(
            task.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        SlaBadge(status: status, dense: true),
      ],
    );

    final Widget progressBar = Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: 6,
          child: LinearProgressIndicator(
            value: (task.progress / 100).clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(slaForeground(status)),
          ),
        ),
      ),
    );

    final Widget row = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          titleRow,
          const SizedBox(height: 4),
          Text(
            '${task.project} - $due',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              progressBar,
              _gap(8),
              Text('${task.progress}%', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: row,
        ),
      ),
    );
  }
}

/// One line of this member's trail
class _TrailRow extends StatelessWidget {
  const _TrailRow({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final Widget dot = const Icon(Icons.circle, size: 8, color: AppColors.primary);

    final Widget message = Expanded(
      child: Text(activity.message, style: const TextStyle(fontSize: 13)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[dot, _gap(10), message, _gap(8), Text(_timeAgo(activity.at), style: const TextStyle(fontSize: 12, color: AppColors.muted))],
      ),
    );
  }
}