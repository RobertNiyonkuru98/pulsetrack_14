import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/models/member.dart';
import '../data/models/task.dart';
import '../state/app_state.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  late String _project;
  late String _assigneeId;
  late DateTime _dueDate;
  late Priority _priority;
  late TaskStatus _status;
  late int _progress;

  bool _submitted = false;

  final List<String> _projectOptions = [
    'UI/UX Design',
    'Mobile Development',
    'Backend (Local)',
    'Quality Assurance',
    'Documentation',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();

    if (widget.taskId != null) {
      final task = state.tasks.firstWhere(
        (t) => t.id == widget.taskId,
        orElse: () => Task(
          id: '',
          title: '',
          assigneeId: '',
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(days: 7)),
        ),
      );
      _title = task.title;
      _description = task.description;
      _project = task.project;
      _assigneeId = task.assigneeId;
      _dueDate = task.dueDate;
      _priority = task.priority;
      _status = task.status;
      _progress = task.progress;
    } else {
      _title = '';
      _description = '';
      _project = 'UI/UX Design';
      _assigneeId = state.members.isNotEmpty ? state.members.first.id : '';
      _dueDate = DateTime.now().add(const Duration(days: 7));
      _priority = Priority.medium;
      _status = TaskStatus.todo;
      _progress = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEditing = widget.taskId != null;

    final isPastDate = _dueDate.isBefore(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ));

    final Member? selectedAssignee = state.memberById(_assigneeId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF1F5F9),
            ),
            child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF334155)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Edit Task' : 'Create Task',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '• Draft',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1D3B8B),
              child: Text(
                state.currentUser?.initials ?? 'PT',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subheading
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_rounded, size: 22, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Edit task' : 'New task',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Field 1: Task Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Task Title *',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  if (_submitted && _title.trim().isEmpty)
                    Row(
                      children: const [
                        Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Required',
                          style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: (_submitted && _title.trim().isEmpty) ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF5B47FB), width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                onSaved: (val) => _title = val ?? '',
              ),
              const SizedBox(height: 20),

              // Field 2: Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _description,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter task description (e.g. scope, requirements, acceptance criteria)...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF5B47FB), width: 1.5),
                  ),
                ),
                onSaved: (val) => _description = val ?? '',
              ),
              const SizedBox(height: 20),

              // Field 3: Project
              const Text(
                'Project',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _projectOptions.contains(_project) ? _project : _projectOptions.first,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    items: _projectOptions.map((proj) {
                      return DropdownMenuItem(
                        value: proj,
                        child: Row(
                          children: [
                            const Icon(Icons.dashboard_customize_outlined, size: 18, color: Color(0xFF5B47FB)),
                            const SizedBox(width: 10),
                            Text(
                              proj,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _project = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Field 4: Assign To
              const Text(
                'Assign To',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _assigneeId.isNotEmpty ? _assigneeId : (state.members.isNotEmpty ? state.members.first.id : null),
                    icon: const Icon(Icons.unfold_more_rounded, color: Color(0xFF64748B)),
                    items: state.members.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFF1D3B8B),
                              child: Text(
                                m.initials,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  m.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  m.role,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _assigneeId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Field 5: Due Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Due Date',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  if (isPastDate)
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Past Date',
                          style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isPastDate ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: isPastDate ? const Color(0xFFEF4444) : const Color(0xFF5B47FB),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_dueDate.day} ${_monthName(_dueDate.month)} ${_dueDate.year}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isPastDate ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.edit_calendar_outlined, size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              if (isPastDate) ...[
                const SizedBox(height: 4),
                const Text(
                  'Due date must be in the future',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                ),
              ],
              const SizedBox(height: 20),

              // Field 6: Priority (Segmented Buttons Low | Medium | High | Critical)
              const Text(
                'Priority',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Row(
                children: Priority.values.map((p) {
                  final isSelected = _priority == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF312E81) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF475467),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Field 7: Status
              const Text(
                'Status',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TaskStatus>(
                    isExpanded: true,
                    value: _status,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    items: TaskStatus.values.map((s) {
                      Color dotColor = Colors.grey;
                      if (s == TaskStatus.todo) dotColor = const Color(0xFF3B82F6);
                      if (s == TaskStatus.inProgress) dotColor = const Color(0xFFF59E0B);
                      if (s == TaskStatus.blocked) dotColor = const Color(0xFFEF4444);
                      if (s == TaskStatus.completed) dotColor = const Color(0xFF10B981);

                      return DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              s.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _status = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Field 8: Initial Progress (Not Started | In Flight | Done)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Initial Progress',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_progress%',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ProgressOptionButton(
                      label: 'Not Started',
                      isSelected: _progress == 0,
                      onTap: () => setState(() => _progress = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProgressOptionButton(
                      label: 'In Flight',
                      isSelected: _progress > 0 && _progress < 100,
                      onTap: () => setState(() => _progress = 50),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ProgressOptionButton(
                      label: 'Done',
                      isSelected: _progress == 100,
                      onTap: () => setState(() => _progress = 100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Primary CTA Button: Black Pill "Create Task ->"
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
                  onPressed: () async {
                    setState(() => _submitted = true);
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      final task = Task(
                        id: widget.taskId ?? const Uuid().v4(),
                        title: _title.trim(),
                        description: _description.trim(),
                        project: _project,
                        assigneeId: _assigneeId,
                        createdAt: isEditing ? (state.tasks.firstWhere((t) => t.id == widget.taskId).createdAt) : DateTime.now(),
                        dueDate: _dueDate,
                        priority: _priority,
                        status: _status,
                        progress: _progress,
                      );

                      await state.saveTask(task, isNew: !isEditing);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Save Changes' : 'Create Task',
                        style: const TextStyle(
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

              // Cancel button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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

class _ProgressOptionButton extends StatelessWidget {
  const _ProgressOptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B47FB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF5B47FB) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
