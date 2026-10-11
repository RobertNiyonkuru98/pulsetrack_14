import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member.dart';
import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../logic/sla_engine.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class TaskDetailsScreen extends StatefulWidget {
  const TaskDetailsScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  int _activeTab = 0; // 0 = Overview, 1 = PARAMETERS

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final task = state.tasks.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => Task(
        id: '',
        title: 'Task Not Found',
        assigneeId: '',
        createdAt: DateTime.now(),
        dueDate: DateTime.now(),
      ),
    );

    if (task.id.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Not Found'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Could not load this task.')),
      );
    }

    final Member? assignee = state.memberById(task.assigneeId);
    final SlaStatus status = state.statusOf(task);
    final String explanation = state.explainStatus(task);
    final double elapsedRatio = SlaEngine.elapsedPercent(task, DateTime.now()).clamp(0.0, 1.0);
    final int elapsedPercent = (elapsedRatio * 100).toInt();

    // Theming according to SLA Status
    Color slaCardBg;
    Color slaCardBorder;
    Color slaBadgeBg;
    Color slaTextColor;
    IconData slaIcon;

    switch (status) {
      case SlaStatus.onTrack:
        slaCardBg = const Color(0xFFEAF8F1);
        slaCardBorder = const Color(0xFFC7EED7);
        slaBadgeBg = const Color(0xFF12A150);
        slaTextColor = const Color(0xFF064E3B);
        slaIcon = Icons.verified_user_outlined;
        break;
      case SlaStatus.atRisk:
        slaCardBg = const Color(0xFFFFF7ED);
        slaCardBorder = const Color(0xFFFDE4C3);
        slaBadgeBg = const Color(0xFFF59E0B);
        slaTextColor = const Color(0xFF78350F);
        slaIcon = Icons.warning_amber_rounded;
        break;
      case SlaStatus.overdue:
        slaCardBg = const Color(0xFFFEF2F2);
        slaCardBorder = const Color(0xFFFECDCA);
        slaBadgeBg = const Color(0xFFEF4444);
        slaTextColor = const Color(0xFF7F1D1D);
        slaIcon = Icons.error_outline_rounded;
        break;
      case SlaStatus.completed:
        slaCardBg = const Color(0xFFF0FDF4);
        slaCardBorder = const Color(0xFFBBF7D0);
        slaBadgeBg = const Color(0xFF16A34A);
        slaTextColor = const Color(0xFF14532D);
        slaIcon = Icons.check_circle_outline_rounded;
        break;
    }

    final now = DateTime.now();
    final differenceDays = task.dueDate.difference(now).inDays;
    final deadlineText = differenceDays >= 0
        ? 'Deadline in $differenceDays days'
        : 'Overdue by ${now.difference(task.dueDate).inDays} days';

    final dateStr = '${task.dueDate.day} ${_monthName(task.dueDate.month)} ${task.dueDate.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
              ),
              child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF334155)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                '${task.dueDate.day} ${_monthName(task.dueDate.month)} • Due Date',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF1F5F9),
              ),
              child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF334155)),
            ),
            onPressed: () => Navigator.pushNamed(context, Routes.taskForm, arguments: task.id),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle & Status tag row
            Row(
              children: [
                Text(
                  task.project.isNotEmpty ? task.project : 'General',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: slaBadgeBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Assignee Avatar Stack preview
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    assignee?.initials ?? '?',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  assignee?.name ?? 'Assigned to Team',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabs (Overview / PARAMETERS)
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _activeTab = 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _activeTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 2.5,
                        width: 60,
                        color: _activeTab == 0 ? const Color(0xFF0F172A) : Colors.transparent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () => setState(() => _activeTab = 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PARAMETERS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: _activeTab == 1 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2.5,
                        width: 90,
                        color: _activeTab == 1 ? const Color(0xFF0F172A) : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Card 1: Assignee and Parameters Grid
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  // Assignee banner
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          assignee?.initials ?? '?',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ASSIGNED TO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  assignee?.name ?? 'Unassigned',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                            Text(
                              assignee?.role ?? 'Team Member',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2-Column Grid (Due Date on left, Priority & Status on right)
                  Row(
                    children: [
                      // Due Date Card (Purple aesthetic)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    'DUE DATE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'All day delivery',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Priority & Status on right
                      Expanded(
                        child: Column(
                          children: [
                            // Priority Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PRIORITY',
                                        style: TextStyle(
                                          color: Color(0xFF991B1B),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        task.priority.label,
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.priority_high_rounded, size: 16, color: Color(0xFFDC2626)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Status Box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'STATUS',
                                        style: TextStyle(
                                          color: Color(0xFF92400E),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        task.status.label,
                                        style: const TextStyle(
                                          color: Color(0xFFB45309),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  PopupMenuButton<TaskStatus>(
                                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFFB45309)),
                                    onSelected: (newStatus) {
                                      state.changeTaskStatus(task, newStatus);
                                    },
                                    itemBuilder: (context) => TaskStatus.values.map((s) {
                                      return PopupMenuItem(
                                        value: s,
                                        child: Text(s.label),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Card 2: SLA Status Card (Explainable Engine)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: slaCardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: slaCardBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(slaIcon, color: slaTextColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'SLA Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: slaTextColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: slaBadgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '• ${status.label.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    explanation,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: slaTextColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // SLA Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: elapsedRatio,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.6),
                      valueColor: AlwaysStoppedAnimation<Color>(slaBadgeBg),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: slaTextColor),
                          const SizedBox(width: 6),
                          Text(
                            deadlineText,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: slaTextColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: slaCardBorder),
                        ),
                        child: Text(
                          '$elapsedPercent% USED',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: slaTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Card 3: Notes & Instructions
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // Quick note editing or alert
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notes saved.')),
                          );
                        },
                        child: const Text(
                          'Add Note',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.subject_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 6),
                            Text(
                              'HANDOFF INSTRUCTIONS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description.isNotEmpty
                              ? task.description
                              : 'Review Figma prototype with client and align token variables before handover. Verify accessibility contrast metrics on primary login CTA.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            // Primary: Black Pill "Edit Task ->"
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                onPressed: () => Navigator.pushNamed(context, Routes.taskForm, arguments: task.id),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary: "Mark Complete"
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                ),
                onPressed: () async {
                  await state.changeTaskStatus(
                    task,
                    task.status == TaskStatus.completed ? TaskStatus.inProgress : TaskStatus.completed,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          task.status == TaskStatus.completed ? 'Task reopened' : 'Task marked complete!',
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      task.status == TaskStatus.completed
                          ? Icons.refresh_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 20,
                      color: const Color(0xFF334155),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.status == TaskStatus.completed ? 'Reopen Task' : 'Mark Complete',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
