import 'package:flutter/material.dart';

import '../data/models/member.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';

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
    final SlaStatus status = state.statusOf(task);
    final Member? assignee = state.memberById(task.assigneeId);

    // Color definitions mapped to the Figma aesthetic
    Color cardBg;
    Color cardBorder;
    Color statusBg;
    Color statusTextColor;
    Color titleColor;
    Color metaColor;
    IconData metaIcon;
    String metaLabel;

    final now = DateTime.now();
    final differenceDays = task.dueDate.difference(now).inDays;

    switch (status) {
      case SlaStatus.onTrack:
        cardBg = const Color(0xFFEAF8F1);
        cardBorder = const Color(0xFFC7EED7);
        statusBg = const Color(0xFF12A150);
        statusTextColor = Colors.white;
        titleColor = const Color(0xFF064E3B);
        metaColor = const Color(0xFF047857);
        metaIcon = Icons.access_time_rounded;
        metaLabel = differenceDays >= 0 ? '$differenceDays days left' : 'On schedule';
        break;
      case SlaStatus.atRisk:
        cardBg = const Color(0xFFFFF7ED);
        cardBorder = const Color(0xFFFDE4C3);
        statusBg = const Color(0xFFF59E0B);
        statusTextColor = Colors.white;
        titleColor = const Color(0xFF78350F);
        metaColor = const Color(0xFFB45309);
        metaIcon = Icons.access_time_rounded;
        metaLabel = 'Action required';
        break;
      case SlaStatus.overdue:
        cardBg = const Color(0xFFFEF2F2);
        cardBorder = const Color(0xFFFECDCA);
        statusBg = const Color(0xFFEF4444);
        statusTextColor = Colors.white;
        titleColor = const Color(0xFF7F1D1D);
        metaColor = const Color(0xFFB91C1C);
        metaIcon = Icons.warning_amber_rounded;
        final overdueDays = now.difference(task.dueDate).inDays;
        metaLabel = overdueDays > 0 ? 'Overdue by $overdueDays days' : 'Overdue today';
        break;
      case SlaStatus.completed:
        cardBg = const Color(0xFFF0FDF4);
        cardBorder = const Color(0xFFBBF7D0);
        statusBg = const Color(0xFF16A34A);
        statusTextColor = Colors.white;
        titleColor = const Color(0xFF14532D);
        metaColor = const Color(0xFF15803D);
        metaIcon = Icons.check_circle_outline_rounded;
        metaLabel = 'Completed';
        break;
    }

    Color priorityDotColor;
    switch (task.priority) {
      case Priority.critical:
        priorityDotColor = const Color(0xFFDC2626);
        break;
      case Priority.high:
        priorityDotColor = const Color(0xFFEA580C);
        break;
      case Priority.medium:
        priorityDotColor = const Color(0xFFF59E0B);
        break;
      case Priority.low:
        priorityDotColor = const Color(0xFF10B981);
        break;
    }

    final dateStr = '${task.dueDate.day} ${_monthName(task.dueDate.month)} ${task.dueDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.pushNamed(
            context,
            Routes.taskDetails,
            arguments: task.id,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Status pill + Category pill + More dots
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder, width: 1),
                      ),
                      child: Text(
                        task.project.isNotEmpty ? task.project : 'General',
                        style: const TextStyle(
                          color: Color(0xFF475467),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      child: const Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Task Title
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),

                // Due date & status alert
                Row(
                  children: [
                    Icon(metaIcon, size: 14, color: metaColor),
                    const SizedBox(width: 6),
                    Text(
                      '$dateStr  •  $metaLabel',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: metaColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Divider line inside card
                Container(
                  height: 1,
                  color: cardBorder.withOpacity(0.7),
                ),
                const SizedBox(height: 12),

                // Bottom row: Assignee & Priority
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF1D3B8B),
                          child: Text(
                            assignee?.initials ?? '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ASSIGNED TO',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              assignee?.name ?? 'Unassigned',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: priorityDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.priority.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
