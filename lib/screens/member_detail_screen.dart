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
import '../widgets/activity_tile.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/sla_badge.dart';

/// Member Detail. OWNER: Admire.
///
/// Opened from the Team Members screen (Routes.memberDetail, arguments = the
/// member id).
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
      return _notFound(context);
    }

    // Everything this screen needs, in three plain variables.
    final List<Task> tasks = state.tasksFor(member.id);
    final List<Activity> trail = state.activity
        .where((Activity a) => a.memberId == member.id)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            _topBar(context),
            _gap(12),
            _HeaderCard(
              member: member,
              onAssign: () => Navigator.pushNamed(context, Routes.taskForm),
            ),
            _gap(24),
            _heading('SLA overview'),
            _gap(12),
            _StatusRow(state: state, tasks: tasks),
            _gap(24),
            _heading('Assigned tasks (${tasks.length})'),
            _gap(12),
            if (tasks.isEmpty)
              const _MutedText('No tasks assigned to this member yet.')
            else
              ..._taskCards(context, state, tasks),
            _gap(12),
            _heading('Recent activity'),
            _gap(12),
            if (trail.isEmpty)
              const _MutedText('Nothing yet. Actions by this member appear here.')
            else
              for (final Activity a in trail.take(5)) ...<Widget>[
                ActivityTile(activity: a, initials: member.initials),
                _gap(10),
              ],
          ],
        ),
      ),
    );
  }

  // ============================================================== build

  Widget _topBar(BuildContext context) {
    return Row(
      children: <Widget>[
        CircleIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
        const Expanded(
          child: Text(
            'Team member',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ),
        // Keeps the title centred, same width as the back button.
        const SizedBox(width: 44),
      ],
    );
  }

  Widget _notFound(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircleIconButton(
                  icon: Icons.arrow_back,
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Member not found',
                message: 'This member may have been removed from the team.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _taskCards(BuildContext context, AppState state, List<Task> tasks) {
    return <Widget>[
      for (final Task t in tasks) ...<Widget>[
        _TaskCard(
          task: t,
          status: state.statusOf(t),
          onTap: () => Navigator.pushNamed(
            context,
            Routes.taskDetails,
            arguments: t.id,
          ),
        ),
        _gap(10),
      ],
    ];
  }
}

// ================================================================ file helpers

/// A spacer that works in both directions: `size` wide inside a Row and `size`
/// tall inside a Column, so the same helper reads the same way in either layout.
///
/// It must set **both** dimensions. A `SizedBox(height: n)` has a width of zero,
/// so using one for horizontal spacing silently butts two widgets together.
Widget _gap([double size = 16]) => SizedBox(width: size, height: size);


Widget _heading(String text) => Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
    );

/// "Due in 2 days", "Due in 18 hours", "Overdue by 1 day" or "Completed".
String _dueLabel(Task task, SlaStatus status) {
  if (status == SlaStatus.completed) return 'Completed';

  final Duration diff = task.dueDate.difference(DateTime.now());
  final bool late = diff.isNegative;
  final Duration abs = late ? -diff : diff;

  final String span;
  if (abs.inHours < 24) {
    final int h = abs.inHours < 1 ? 1 : abs.inHours;
    span = '$h ${h == 1 ? 'hour' : 'hours'}';
  } else {
    span = '${abs.inDays} ${abs.inDays == 1 ? 'day' : 'days'}';
  }
  return late ? 'Overdue by $span' : 'Due in $span';
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

/// Centred avatar, name, role pill, email and the "Assign task" button.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.member, required this.onAssign});

  final Member member;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final Widget rolePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        member.role,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: <Widget>[
          MemberAvatar(member: member, size: 88),
          _gap(12),
          Text(
            member.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          _gap(8),
          rolePill,
          if (member.email.isNotEmpty) ...<Widget>[
            _gap(8),
            Text(member.email, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
          _gap(16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Assign task'),
            ),
          ),
        ],
      ),
    );
  }
}

/// The four SLA counts as pastel cards, colour-coded like every SLA surface.
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
      final SlaStatus s = state.statusOf(t);
      counts[s] = counts[s]! + 1;
    }

    // Done last, because that is the order a reader expects.
    const List<(SlaStatus, String)> order = <(SlaStatus, String)>[
      (SlaStatus.onTrack, 'On track'),
      (SlaStatus.atRisk, 'At risk'),
      (SlaStatus.overdue, 'Overdue'),
      (SlaStatus.completed, 'Done'),
    ];

    final List<Widget> cards = <Widget>[];
    for (int i = 0; i < order.length; i++) {
      final (SlaStatus status, String label) = order[i];
      if (i > 0) cards.add(const SizedBox(width: 8));
      cards.add(Expanded(child: _StatusCard(label: label, value: counts[status]!, status: status)));
    }

    return Row(children: cards);
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.label, required this.value, required this.status});

  final String label;
  final int value;
  final SlaStatus status;

  @override
  Widget build(BuildContext context) {
    final Color text = slaForeground(status);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: AppTheme.pastelCard(slaBackground(status)),
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(fontSize: 24, height: 1, fontWeight: FontWeight.w700, color: text),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
          ),
        ],
      ),
    );
  }
}

/// One task of this member as a pastel card filled with its SLA colour:
/// status pill, priority pill, title, project, due label and progress.
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.status, required this.onTap});

  final Task task;
  final SlaStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color text = slaForeground(status);

    final Widget pills = Row(
      children: <Widget>[
        SlaBadge(status: status, dense: true, onColor: true),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            task.priority.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
          ),
        ),
      ],
    );

    final Widget progress = Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: (task.progress / 100).clamp(0.0, 1.0),
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.black),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${task.progress}%', style: TextStyle(fontSize: 11, color: text)),
      ],
    );

    return Material(
      color: slaBackground(status),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              pills,
              const SizedBox(height: 12),
              Text(
                task.title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text),
              ),
              const SizedBox(height: 2),
              Text(
                '${task.project}  ·  ${_dueLabel(task, status)}',
                style: TextStyle(fontSize: 12, color: text),
              ),
              const SizedBox(height: 12),
              progress,
            ],
          ),
        ),
      ),
    );
  }
}