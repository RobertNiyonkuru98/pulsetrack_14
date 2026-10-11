import 'package:flutter/material.dart';

import '../data/models/activity.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// "just now", "5m ago", "2h ago", "3d ago", then a short date.
String activityTimeAgo(DateTime at) {
  final Duration d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${at.day}/${at.month}/${at.year}';
}


class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.activity, required this.initials});

  final Activity activity;

  /// Initials of the member who did it, shown in the small avatar.
  final String initials;

  IconData get _icon => switch (activity.type) {
        ActivityType.created => Icons.add_task,
        ActivityType.assigned => Icons.person_add_alt_1_outlined,
        ActivityType.statusChanged => Icons.swap_vert_rounded,
        ActivityType.completed => Icons.check_circle_outline,
        ActivityType.updated => Icons.edit_outlined,
      };

  /// (pastel fill, dark text) for the event type.
  (Color, Color) get _scheme => switch (activity.type) {
        ActivityType.created => (AppColors.sky, const Color(0xFF0A3D5C)),
        ActivityType.assigned => (AppColors.primarySoft, AppColors.primary),
        ActivityType.statusChanged => (AppColors.atRiskSoft, AppColors.atRiskText),
        ActivityType.completed => (AppColors.onTrackSoft, AppColors.onTrackText),
        ActivityType.updated => (AppColors.neutral, AppColors.completedText),
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
    final (Color fill, Color text) = _scheme;

    final Widget iconCircle = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: Icon(_icon, size: 20, color: text),
    );

    final Widget typePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(999)),
      child: Text(
        _label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );

    final Widget avatar = CircleAvatar(
      radius: 11,
      backgroundColor: AppColors.neutral,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
    );

    final Widget footer = Row(
      children: <Widget>[
        avatar,
        const SizedBox(width: 8),
        typePill,
        const Spacer(),
        Text(
          activityTimeAgo(activity.at),
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          iconCircle,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  activity.message,
                  style: const TextStyle(fontSize: 14, height: 1.35, color: AppColors.ink),
                ),
                const SizedBox(height: 10),
                footer,
              ],
            ),
          ),
        ],
      ),
    );
  }
}