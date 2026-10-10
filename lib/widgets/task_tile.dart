import 'package:flutter/material.dart';

import '../data/models/member.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import 'sla_badge.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.state,
  });

  final Task task;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final Member? assignee = state.memberById(task.assigneeId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(task.project, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    assignee?.initials ?? '?',
                    style: const TextStyle(fontSize: 10, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Due ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const Spacer(),
                SlaBadge(status: state.statusOf(task)),
              ],
            )
          ],
        ),
        onTap: () => Navigator.pushNamed(
          context,
          Routes.taskDetails,
          arguments: task.id,
        ),
      ),
    );
  }
}
