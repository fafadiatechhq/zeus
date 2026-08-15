class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String avatarInitials;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.avatarInitials,
  });

  /// Maps `zeus.api.mobile.get_session` / login `session` payload.
  factory User.fromSession(Map<String, dynamic> json) {
    final name = _string(json['full_name']).isNotEmpty
        ? _string(json['full_name'])
        : _string(json['employee_name']);
    return User(
      id: _string(json['employee'], fallback: _string(json['user'])),
      name: name,
      email: _string(json['email']),
      phone: _string(json['phone']),
      role: _string(json['designation']),
      department: _string(json['department']),
      avatarInitials: initialsFor(name),
    );
  }

  static String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}
