/// How urgent a task is. Priority also decides how early we warn (see SlaEngine).
enum Priority { low, medium, high, critical }

/// The stage a task is in.
enum TaskStatus { todo, inProgress, blocked, completed }

extension PriorityLabel on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.critical:
        return 'Critical';
    }
  }
}

extension TaskStatusLabel on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

/// Enums are saved to SQLite by name, so these two helpers are how we read them back.
Priority priorityFromName(String name) => Priority.values.firstWhere(
      (Priority p) => p.name == name,
      orElse: () => Priority.medium,
    );

TaskStatus taskStatusFromName(String name) => TaskStatus.values.firstWhere(
      (TaskStatus s) => s.name == name,
      orElse: () => TaskStatus.todo,
    );

/// A single unit of work on a project.
class Task {
  final String id;
  final String title;
  final String description;
  final String project;
  final String assigneeId;
  final DateTime createdAt;
  final DateTime dueDate;
  final Priority priority;
  final TaskStatus status;
  final int progress; // 0 to 100

  const Task({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.createdAt,
    required this.dueDate,
    this.description = '',
    this.project = 'General',
    this.priority = Priority.medium,
    this.status = TaskStatus.todo,
    this.progress = 0,
  });

  Task copyWith({
    String? title,
    String? description,
    String? project,
    String? assigneeId,
    DateTime? dueDate,
    Priority? priority,
    TaskStatus? status,
    int? progress,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        project: project ?? this.project,
        assigneeId: assigneeId ?? this.assigneeId,
        createdAt: createdAt,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        progress: progress ?? this.progress,
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'description': description,
        'project': project,
        'assigneeId': assigneeId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'priority': priority.name,
        'status': status.name,
        'progress': progress,
      };

  factory Task.fromMap(Map<String, Object?> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: (map['description'] as String?) ?? '',
        project: (map['project'] as String?) ?? 'General',
        assigneeId: (map['assigneeId'] as String?) ?? '',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
        priority: priorityFromName(map['priority'] as String),
        status: taskStatusFromName(map['status'] as String),
        progress: (map['progress'] as int?) ?? 0,
      );
}
