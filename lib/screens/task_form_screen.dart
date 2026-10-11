import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/task.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

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
  late String _assigneeId;
  late DateTime _dueDate;
  late Priority _priority;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    
    if (widget.taskId != null) {
      final task = state.tasks.firstWhere((t) => t.id == widget.taskId);
      _title = task.title;
      _description = task.description;
      _assigneeId = task.assigneeId;
      _dueDate = task.dueDate;
      _priority = task.priority;
      _status = task.status;
    } else {
      _title = '';
      _description = '';
      _assigneeId = state.members.isNotEmpty ? state.members.first.id : '';
      _dueDate = DateTime.now().add(const Duration(days: 7));
      _priority = Priority.medium;
      _status = TaskStatus.todo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isEditing = widget.taskId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Create Task', style: const TextStyle(color: AppColors.ink)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Task Title', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _title,
                decoration: InputDecoration(
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                onSaved: (val) => _title = val!,
              ),
              
              const SizedBox(height: 24),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _description,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter task description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onSaved: (val) => _description = val ?? '',
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.person_outline, color: AppColors.muted),
                  const SizedBox(width: 12),
                  const SizedBox(width: 100, child: Text('Assign To', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _assigneeId.isNotEmpty ? _assigneeId : null,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: state.members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                      onChanged: (val) => setState(() => _assigneeId = val!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.muted),
                  const SizedBox(width: 12),
                  const SizedBox(width: 100, child: Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _dueDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.flag_outlined, color: AppColors.muted),
                  const SizedBox(width: 12),
                  const SizedBox(width: 100, child: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: DropdownButtonFormField<Priority>(
                      value: _priority,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.label))).toList(),
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.list_alt, color: AppColors.muted),
                  const SizedBox(width: 12),
                  const SizedBox(width: 100, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                    child: DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: TaskStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                      onChanged: (val) => setState(() => _status = val!),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      // Normally we would save to AppState here
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Save Changes' : 'Create Task', style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
