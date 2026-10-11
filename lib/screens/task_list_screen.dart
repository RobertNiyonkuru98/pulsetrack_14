import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/sla_status.dart';
import '../data/models/task.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/task_tile.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  String _searchQuery = '';
  SlaStatus? _filterStatus;
  String _sortBy = 'dueDate'; // 'dueDate', 'priority', 'title'

  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    // Filter tasks based on search and SLA status
    List<Task> filteredTasks = state.tasks.where((Task t) {
      if (_searchQuery.isNotEmpty &&
          !t.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !t.project.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filterStatus != null) {
        final SlaStatus status = state.statusOf(t);
        if (status != _filterStatus) return false;
      }
      return true;
    }).toList();

    // Sort tasks
    filteredTasks.sort((Task a, Task b) {
      if (_sortBy == 'dueDate') {
        return a.dueDate.compareTo(b.dueDate);
      } else if (_sortBy == 'priority') {
        return b.priority.index.compareTo(a.priority.index);
      } else {
        return a.title.compareTo(b.title);
      }
    });

    final totalCount = state.tasks.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.ink),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          children: const [
            Text(
              'Tasks',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Workspace Sprint 4',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
              child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF334155)),
            ),
            onPressed: () {
              // Toggle sorting mode
              setState(() {
                if (_sortBy == 'dueDate') {
                  _sortBy = 'priority';
                } else if (_sortBy == 'priority') {
                  _sortBy = 'title';
                } else {
                  _sortBy = 'dueDate';
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Sorting by: ${_sortBy == 'dueDate' ? 'Due Date' : _sortBy == 'priority' ? 'Priority' : 'Title'}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input with Mic icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                    suffixIcon: Icon(Icons.mic_none_rounded, color: Color(0xFF64748B), size: 22),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),

            // Horizontal SLA Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  _FilterPill(
                    label: 'All $totalCount',
                    isSelected: _filterStatus == null,
                    onTap: () => setState(() => _filterStatus = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'On Track',
                    dotColor: const Color(0xFF12A150),
                    isSelected: _filterStatus == SlaStatus.onTrack,
                    onTap: () => setState(() => _filterStatus = SlaStatus.onTrack),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'At Risk',
                    dotColor: const Color(0xFFF59E0B),
                    isSelected: _filterStatus == SlaStatus.atRisk,
                    onTap: () => setState(() => _filterStatus = SlaStatus.atRisk),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Overdue',
                    dotColor: const Color(0xFFEF4444),
                    isSelected: _filterStatus == SlaStatus.overdue,
                    onTap: () => setState(() => _filterStatus = SlaStatus.overdue),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Completed',
                    dotColor: const Color(0xFF64748B),
                    isSelected: _filterStatus == SlaStatus.completed,
                    onTap: () => setState(() => _filterStatus = SlaStatus.completed),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Task list count & sort bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      text: '${filteredTasks.length} tasks',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      children: const [
                        TextSpan(
                          text: '  •  Sprint ready',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        if (_sortBy == 'dueDate') {
                          _sortBy = 'priority';
                        } else if (_sortBy == 'priority') {
                          _sortBy = 'title';
                        } else {
                          _sortBy = 'dueDate';
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'Sort: ${_sortBy == 'dueDate' ? 'Due date' : _sortBy == 'priority' ? 'Priority' : 'Title'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475467),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Main Task Feed
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty ? 'No tasks match "$_searchQuery"' : 'No tasks in this category',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return TaskTile(task: task, state: state);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () => Navigator.pushNamed(context, Routes.taskForm),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null && !isSelected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF475467),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
