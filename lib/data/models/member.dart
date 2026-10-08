/// A person on the team.
class Member {
  final String id;
  final String name;
  final String role;
  final String email;

  const Member({
    required this.id,
    required this.name,
    required this.role,
    this.email = '',
  });

  /// "Sarah Lee" -> "SL". Used by every avatar in the app.
  String get initials {
    final List<String> parts =
        name.trim().split(' ').where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'role': role,
        'email': email,
      };

  factory Member.fromMap(Map<String, Object?> map) => Member(
        id: map['id'] as String,
        name: map['name'] as String,
        role: map['role'] as String,
        email: (map['email'] as String?) ?? '',
      );
}
