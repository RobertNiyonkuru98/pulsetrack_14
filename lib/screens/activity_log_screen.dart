import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/activity.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';

/// Activity Log. OWNER: Admire.
///
/// The full audit trail of all member activity
///
class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Widget body;
    if (state.activity.isEmpty) {
      body = const EmptyState(
        icon: Icons.history_toggle_off,
        title: 'No activity yet',
        message: 'Create or update a task and it will appear here.',
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.activity.length,
        separatorBuilder: (BuildContext context, int index) => _gap(10),
        itemBuilder: (BuildContext context, int index) {
          final Activity a = state.activity[index];
          return _ActivityTile(
            activity: a,
            initials: state.memberById(a.memberId)?.initials ?? '?',
          );
        },
      );
    }

    final Widget refreshButton = IconButton(
      tooltip: 'Refresh',
      icon: const Icon(Icons.refresh),
      onPressed: () => state.refresh(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Log'),
        actions: <Widget>[refreshButton],
      ),
      body: body,
    );
  }
}

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

/// avatar, message, type chip, time stamp.
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.initials});

  final Activity activity;
  final String initials;

  IconData get _icon => switch (activity.type) {
        ActivityType.created => Icons.add_circle_outline,
        ActivityType.assigned => Icons.person_add_alt_outlined,
        ActivityType.statusChanged => Icons.swap_vert,
        ActivityType.completed => Icons.check_circle_outline,
        ActivityType.updated => Icons.edit_outlined,
      };

  Color get _color => switch (activity.type) {
        ActivityType.created => AppColors.primary,
        ActivityType.assigned => AppColors.primary,
        ActivityType.statusChanged => AppColors.atRisk,
        ActivityType.completed => AppColors.onTrack,
        ActivityType.updated => AppColors.muted,
      };

  String get _label => switch (activity.type) {
        ActivityType.created => 'Created',
        ActivityType.assigned => 'Assigned',
        ActivityType.statusChanged => 'Status',
        ActivityType.completed => 'Completed',
        ActivityType.updated => 'Updated',
      };

  @override
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.border.withValues(alpha: 0.5),
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );

    final Widget message = Text(
      activity.message,
      style: const TextStyle(fontSize: 13, color: AppColors.ink),
    );

    final Widget typeChip = Row(
      children: <Widget>[
        Icon(_icon, size: 14, color: _color),
        const SizedBox(width: 4),
        Text(
          _label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _color),
        ),
      ],
    );

    final Widget stamp = Flexible(
      child: Text(
        _timeAgo(activity.at),
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      ),
    );

    final Widget text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[message, const SizedBox(height: 6), Row(children: <Widget>[typeChip, _gap(8), stamp])],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[avatar, _gap(12), text],
      ),
    );
  }
}