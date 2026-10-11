import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../logic/sla_engine.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/avatar_stack.dart';
import '../widgets/empty_state.dart';
import '../widgets/sla_badge.dart';

/// Team Members. OWNER: Admire.
///
/// The "Team" bottom-nav tab: three pastel summary cards, then one card per
/// member showing how many of their open tasks are On Track, At Risk or
/// Overdue. Tapping a member opens Member Detail.
///
class TeamMembersScreen extends StatelessWidget {
  const TeamMembersScreen({super.key});

  /// SLA status of every task a member owns, using the live settings.
  Map<SlaStatus, int> _countsFor(AppState state, Member member) {
    final Map<SlaStatus, int> counts = <SlaStatus, int>{
      for (final SlaStatus s in SlaStatus.values) s: 0,
    };
    for (final Task task in state.tasks) {
      if (task.assigneeId != member.id) continue;
      final SlaStatus status = SlaEngine.evaluate(task, settings: state.settings);
      counts[status] = counts[status]! + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // One pass over the tasks gives the two summary numbers.
    int open = 0;
    int overdue = 0;
    for (final Task task in state.tasks) {
      final SlaStatus status = SlaEngine.evaluate(task, settings: state.settings);
      if (status != SlaStatus.completed) open++;
      if (status == SlaStatus.overdue) overdue++;
    }

    final Widget body;
    if (state.members.isEmpty) {
      body = const EmptyState(
        icon: Icons.groups_outlined,
        title: 'No team members yet',
        message: 'Members will appear here once they are added.',
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: <Widget>[
          _headline(),
          _summaryRow(state.members.length, open, overdue),
          const SizedBox(height: 20),
          for (final Member m in state.members) ...<Widget>[
            _memberCard(context, m, _countsFor(state, m)),
            const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: SafeArea(child: body),
    );
  }

  // ================================================================ pieces


  Widget _headline() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 24, 0, 16),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: 'Your\n',
              style: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFFAAAAB5)),
            ),
            TextSpan(
              text: 'team',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ],
        ),
        style: TextStyle(fontSize: 38, height: 1.05),
      ),
    );
  }

  Widget _summaryRow(int members, int open, int overdue) {
    return Row(
      children: <Widget>[
        Expanded(child: _summaryCard('$members', 'Members', AppColors.primary, Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('$open', 'Open', AppColors.sky, const Color(0xFF0A3D5C))),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard('$overdue', 'Overdue', AppColors.overdueSoft, AppColors.overdueText),
        ),
      ],
    );
  }

  Widget _summaryCard(String value, String label, Color fill, Color text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.pastelCard(fill),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(fontSize: 28, height: 1, fontWeight: FontWeight.w700, color: text),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: text)),
        ],
      ),
    );
  }

  Widget _memberCard(BuildContext context, Member member, Map<SlaStatus, int> counts) {
    // Only show the statuses the member actually has; skip empty ones.
    final List<Widget> pills = <Widget>[
      for (final SlaStatus s in <SlaStatus>[
        SlaStatus.onTrack,
        SlaStatus.atRisk,
        SlaStatus.overdue,
      ])
        if (counts[s]! > 0) _countPill(s, counts[s]!),
    ];

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        onTap: () => Navigator.pushNamed(context, Routes.memberDetail, arguments: member.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              MemberAvatar(member: member, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.role,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                    if (pills.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: pills),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }


  Widget _countPill(SlaStatus status, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: slaBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count ${status.label}',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: slaForeground(status),
        ),
      ),
    );
  }
}