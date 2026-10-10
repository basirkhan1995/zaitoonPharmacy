class Staff {
  final int staffId;
  final int orgId;
  final String fullName;
  final String role;      // PHARMACIST | ASSISTANT | ADMIN
  final String gender;    // Male | Female | Other
  final String? phone;
  final String? email;
  final String? address;
  final String? hireDate;
  final bool isActive;
  final String? createdAt;
  final String? orgName;

  const Staff({
    required this.staffId,
    required this.orgId,
    required this.fullName,
    required this.role,
    required this.gender,
    this.phone,
    this.email,
    this.address,
    this.hireDate,
    required this.isActive,
    this.createdAt,
    this.orgName,
  });

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
    staffId:   _toInt(j['staff_id']),
    orgId:     _toInt(j['org_id']),
    fullName:  j['full_name'] as String? ?? '',
    role:      j['role'] as String? ?? '',
    gender:    j['gender'] as String? ?? '',
    phone:     j['phone'] as String?,
    email:     j['email'] as String?,
    address:   j['address'] as String?,
    hireDate:  j['hire_date']?.toString().substring(0, 10),
    isActive:  _toBool(j['is_active']),
    createdAt: j['created_at']?.toString(),
    orgName:   j['org_name'] as String?,
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

class StaffRequest {
  final int orgId;
  final String fullName;
  final String role;
  final String gender;
  final String? phone;
  final String? email;
  final String? address;
  final String? hireDate;
  final bool isActive;

  const StaffRequest({
    required this.orgId,
    required this.fullName,
    required this.role,
    required this.gender,
    this.phone,
    this.email,
    this.address,
    this.hireDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'org_id':    orgId,
    'full_name': fullName,
    'role':      role,
    'gender':    gender,
    'phone':     phone,
    'email':     email,
    'address':   address,
    'hire_date': hireDate,
    'is_active': isActive ? 1 : 0,
  };
}