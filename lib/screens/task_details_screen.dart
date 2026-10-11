import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/sla_badge.dart';

class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, this.taskId});

  final String? taskId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final task = state.tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => Task(
        id: '',
        title: 'Not Found',
        assigneeId: '',
        createdAt: DateTime.now(),
        dueDate: DateTime.now(),
      ),
    );

    if (task.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Not Found')),
        body: const Center(child: Text('Could not load this task.')),
      );
    }

    final assignee = state.memberById(task.assigneeId);
    final status = state.statusOf(task);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details', style: TextStyle(color: AppColors.ink)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink),
                  ),
                ),
                SlaBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(task.project, style: const TextStyle(color: AppColors.muted, fontSize: 14)),
            
            const SizedBox(height: 32),
            
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Assigned to',
              valueWidget: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.surface,
                    child: Text(assignee?.initials ?? '?', style: const TextStyle(fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Text(assignee?.name ?? 'Unassigned'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Due Date',
              valueWidget: Text('${task.dueDate.day} ${_monthName(task.dueDate.month)} ${task.dueDate.year}'),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.flag_outlined,
              label: 'Priority',
              valueWidget: Text(task.priority.label, style: const TextStyle(color: AppColors.overdue)),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.list_alt,
              label: 'Status',
              valueWidget: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(task.status.label),
                    const Icon(Icons.arrow_drop_down, size: 16),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('SLA Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: slaBackground(status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: slaForeground(status)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(status.label, style: TextStyle(fontWeight: FontWeight.bold, color: slaForeground(status))),
                        const SizedBox(height: 4),
                        const Text('The task is progressing as expected.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any additional notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushNamed(context, Routes.taskForm, arguments: task.id),
                child: const Text('Edit Task', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.valueWidget});

  final IconData icon;
  final String label;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 12),
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppColors.muted))),
        Expanded(child: valueWidget),
      ],
    );
  }
}
