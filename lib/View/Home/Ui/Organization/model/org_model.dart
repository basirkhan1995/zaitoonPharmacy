import 'dart:io';

class Organization {
  final int orgId;
  final String orgName;
  final String? email;
  final String? contact;
  final String? phone;
  final String? address;
  final String? note;
  final bool hasLogo;

  const Organization({
    required this.orgId,
    required this.orgName,
    this.email,
    this.contact,
    this.phone,
    this.address,
    this.note,
    this.hasLogo = false,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
    orgId:   _toInt(json['org_id']),
    orgName: json['org_name'] as String,
    email:   json['email']   as String?,
    contact: json['contact'] as String?,
    phone:   json['phone']   as String?,
    address: json['address'] as String?,
    note:    json['note']    as String?,
    hasLogo: _toBool(json['has_logo']),
  );

  Map<String, dynamic> toJson() => {
    'org_id':   orgId,
    'org_name': orgName,
    'email':    email,
    'contact':  contact,
    'phone':    phone,
    'address':  address,
    'note':     note,
    'has_logo': hasLogo,
  };

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
    final s = v.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}


class OrganizationRequest {
  final String orgName;
  final String? email;
  final String? contact;
  final String? phone;
  final String? address;
  final String? note;
  /// Optional new logo file. Null = don't change (for update) / no logo (for create).
  final File? logo;

  const OrganizationRequest({
    required this.orgName,
    this.email,
    this.contact,
    this.phone,
    this.address,
    this.note,
    this.logo,
  });

  /// Fields only — used for multipart. Do not call `toJson()` when there's a file.
  Map<String, dynamic> toFields() {
    final map = <String, dynamic>{'org_name': orgName};
    if (email   != null && email!.isNotEmpty)   map['email']   = email;
    if (contact != null && contact!.isNotEmpty) map['contact'] = contact;
    if (phone   != null && phone!.isNotEmpty)   map['phone']   = phone;
    if (address != null && address!.isNotEmpty) map['address'] = address;
    if (note    != null && note!.isNotEmpty)    map['note']    = note;
    return map;
  }
}
