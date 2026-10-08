class User {
  final int userId;
  final int staffId;
  final String username;
  final String fullName;
  final String role;
  final int orgId;
  final String orgName;

  const User({
    required this.userId,
    required this.staffId,
    required this.username,
    required this.fullName,
    required this.role,
    required this.orgId,
    required this.orgName,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId:   (json['user_id']   as num).toInt(),
    staffId:  (json['staff_id']  as num).toInt(),
    username: json['username']   as String,
    fullName: json['full_name']  as String,
    role:     json['role']       as String,
    orgId:    (json['org_id']    as num).toInt(),
    orgName:  json['org_name']   as String,
  );

  Map<String, dynamic> toJson() => {
    'user_id':   userId,
    'staff_id':  staffId,
    'username':  username,
    'full_name': fullName,
    'role':      role,
    'org_id':    orgId,
    'org_name':  orgName,
  };
}

class RegisterRequest {
  final int orgId;
  final String fullName;
  final String username;
  final String password;
  final String role;        // 'PHARMACIST' | 'ASSISTANT' | 'ADMIN'
  final String gender;      // 'Male' | 'Female' | 'Other'
  final String? phone;
  final String? email;
  final String? address;
  final String? hireDate;   // 'YYYY-MM-DD'

  const RegisterRequest({
    required this.orgId,
    required this.fullName,
    required this.username,
    required this.password,
    required this.role,
    required this.gender,
    this.phone,
    this.email,
    this.address,
    this.hireDate,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'org_id':    orgId,
      'full_name': fullName,
      'username':  username,
      'password':  password,
      'role':      role,
      'gender':    gender,
    };
    if (phone    != null && phone!.isNotEmpty)    map['phone']     = phone;
    if (email    != null && email!.isNotEmpty)    map['email']     = email;
    if (address  != null && address!.isNotEmpty)  map['address']   = address;
    if (hireDate != null && hireDate!.isNotEmpty) map['hire_date'] = hireDate;
    return map;
  }
}

class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'] as String,
    user:  User.fromJson(json['user'] as Map<String, dynamic>),
  );
}



