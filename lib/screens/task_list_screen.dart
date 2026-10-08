import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/task.dart';
import '../data/models/sla_status.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/sla_badge.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _searchQuery = '';
  SlaStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();
    
    // Filter tasks based on search and status
    final List<Task> filteredTasks = state.tasks.where((Task t) {
      if (_searchQuery.isNotEmpty && !t.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filterStatus != null) {
        final SlaStatus status = state.statusOf(t);
        if (status != _filterStatus) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(color: AppColors.ink)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        actions: [
          if (state.currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  state.currentUser!.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'On Track',
                  isSelected: _filterStatus == SlaStatus.onTrack,
                  onTap: () => setState(() => _filterStatus = SlaStatus.onTrack),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'At Risk',
                  isSelected: _filterStatus == SlaStatus.atRisk,
                  onTap: () => setState(() => _filterStatus = SlaStatus.atRisk),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Overdue',
                  isSelected: _filterStatus == SlaStatus.overdue,
                  onTap: () => setState(() => _filterStatus = SlaStatus.overdue),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Task List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                final assignee = state.memberById(task.assigneeId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
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
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.muted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
