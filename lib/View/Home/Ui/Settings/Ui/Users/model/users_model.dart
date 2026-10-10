class UserAccount {
  final int userId;
  final int staffId;
  final String username;
  final bool isActive;
  final String? lastLogin;
  final String? createdAt;
  final String? fullName;
  final String? role;

  const UserAccount({
    required this.userId,
    required this.staffId,
    required this.username,
    required this.isActive,
    this.lastLogin,
    this.createdAt,
    this.fullName,
    this.role,
  });

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
    userId:    _toInt(j['user_id']),
    staffId:   _toInt(j['staff_id']),
    username:  j['username'] as String? ?? '',
    isActive:  _toBool(j['is_active']),
    lastLogin: j['last_login']?.toString(),
    createdAt: j['created_at']?.toString(),
    fullName:  j['full_name'] as String?,
    role:      j['role'] as String?,
  );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return v.toString() == '1' || v.toString().toLowerCase() == 'true';
  }
}

class UserAccountRequest {
  final int staffId;
  final String username;
  final String? password; // null or empty on update = keep existing
  final bool isActive;

  const UserAccountRequest({
    required this.staffId,
    required this.username,
    this.password,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'staff_id': staffId,
      'username': username,
      'is_active': isActive ? 1 : 0,
    };
    if (password != null && password!.isNotEmpty) {
      map['password'] = password;
    }
    return map;
  }
}