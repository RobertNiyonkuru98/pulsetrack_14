import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/activity.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/donut_chart.dart';
import '../widgets/health_ring.dart';
import '../widgets/kpi_card.dart';
import '../widgets/sla_badge.dart';

/// Screen 2. This is the reference implementation for the rest of the team:
/// read it to see how we take data from AppState, turn it into SLA statuses,
/// and lay the result out in cards.
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

    final int onTrack = state.countOf(SlaStatus.onTrack);
    final int atRisk = state.countOf(SlaStatus.atRisk);
    final int overdue = state.countOf(SlaStatus.overdue);
    final int completed = state.countOf(SlaStatus.completed);
    final int total = state.tasks.length;
    final List<Task> attention = state.attentionQueue.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Navigator.pushNamed(context, Routes.activity),
        ),
        title: const Text('Dashboard'),
        actions: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () =>
                    Navigator.pushNamed(context, Routes.activity),
              ),
              if (state.attentionQueue.isNotEmpty)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.overdue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            _greeting(state.currentUser?.name.split(' ').first),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Here's what's happening with your project.",
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 18),

          // KPI grid
          Row(
            children: <Widget>[
              Expanded(
                child: KpiCard(
                  label: 'Total Tasks',
                  value: '$total',
                  icon: Icons.list_alt,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: 'On Track',
                  value: '$onTrack',
                  icon: Icons.trending_up,
                  color: AppColors.onTrack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: KpiCard(
                  label: 'At Risk',
                  value: '$atRisk',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.atRisk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: 'Overdue',
                  value: '$overdue',
                  icon: Icons.error_outline,
                  color: AppColors.overdue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'Project Health',
            child: Column(
              children: <Widget>[
                HealthRing(score: state.healthScore),
                const SizedBox(height: 10),
                Text(
                  'Based on the SLA status of $total tasks',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'Task Overview',
            child: Row(
              children: <Widget>[
                DonutChart(
                  slices: <DonutSlice>[
                    DonutSlice(
                      value: onTrack.toDouble(),
                      color: AppColors.onTrack,
                      label: 'On Track',
                    ),
                    DonutSlice(
                      value: atRisk.toDouble(),
                      color: AppColors.atRisk,
                      label: 'At Risk',
                    ),
                    DonutSlice(
                      value: overdue.toDouble(),
                      color: AppColors.overdue,
                      label: 'Overdue',
                    ),
                    DonutSlice(
                      value: completed.toDouble(),
                      color: AppColors.completed,
                      label: 'Completed',
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _Legend(color: AppColors.onTrack, label: 'On Track', value: onTrack),
                      _Legend(color: AppColors.atRisk, label: 'At Risk', value: atRisk),
                      _Legend(color: AppColors.overdue, label: 'Overdue', value: overdue),
                      _Legend(color: AppColors.completed, label: 'Completed', value: completed),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'Attention Needed',
            trailing: TextButton(
              onPressed: () => Navigator.pushNamed(context, Routes.tasks),
              child: const Text('View all'),
            ),
            child: attention.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Nothing needs attention right now.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  )
                : Column(
                    children: attention
                        .map((Task t) => _AttentionRow(task: t, state: state))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 16),

          _SectionCard(
            title: 'Recent Activity',
            child: state.activity.isEmpty
                ? const Text(
                    'No activity yet.',
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  )
                : Column(
                    children: state.activity.take(3).map((Activity a) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: AppColors.border,
                              child: Text(
                                _initialsFor(state, a.memberId),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                a.message,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          Center(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, Routes.insights),
              icon: const Icon(Icons.insights),
              label: const Text('Open Insights'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, Routes.taskForm),
        child: const Icon(Icons.add),
      ),
    );
  }

  static String _greeting(String? firstName) {
    final int hour = DateTime.now().hour;
    final String part = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    return firstName == null ? part : '$part, $firstName';
  }

  static String _initialsFor(AppState state, String memberId) {
    return state.memberById(memberId)?.initials ?? '?';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.task, required this.state});

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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            SlaBadge(status: state.statusOf(task)),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
