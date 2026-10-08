/// The audit trail: one row every time something happens to a task.
enum ActivityType { created, statusChanged, assigned, completed, updated }

ActivityType activityTypeFromName(String name) => ActivityType.values.firstWhere(
      (ActivityType t) => t.name == name,
      orElse: () => ActivityType.updated,
    );

class Activity {
  final String id;
  final String memberId;
  final String message;
  final DateTime at;
  final ActivityType type;

  const Activity({
    required this.id,
    required this.memberId,
    required this.message,
    required this.at,
    this.type = ActivityType.updated,
  });

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'memberId': memberId,
        'message': message,
        'at': at.millisecondsSinceEpoch,
        'type': type.name,
      };

  factory Activity.fromMap(Map<String, Object?> map) => Activity(
        id: map['id'] as String,
        memberId: (map['memberId'] as String?) ?? '',
        message: map['message'] as String,
        at: DateTime.fromMillisecondsSinceEpoch(map['at'] as int),
        type: activityTypeFromName(map['type'] as String),
      );
}
