
class PrescriptionItem {
  final int? prescriptionItemId;
  final int medId;
  final String medName;
  final String? unit;
  final String? dosage;
  final int quantity;
  final String? dosageInstruction;
  final int? durationDays;
  final List<DispensedBatch> dispensedBatches;

  const PrescriptionItem({
    this.prescriptionItemId,
    required this.medId,
    required this.medName,
    this.unit,
    this.dosage,
    required this.quantity,
    this.dosageInstruction,
    this.durationDays,
    this.dispensedBatches = const [],
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) =>
      PrescriptionItem(
        prescriptionItemId: _toInt(json['prescription_item_id']),
        medId:              _toInt(json['med_id']),
        medName:            json['med_name'] as String? ?? '',
        unit:               json['unit'] as String?,
        dosage:             json['dosage'] as String?,
        quantity:           _toInt(json['quantity']),
        dosageInstruction:  json['dosage_instruction'] as String?,
        durationDays:       json['duration_days'] == null
            ? null
            : _toInt(json['duration_days']),
        dispensedBatches:   ((json['dispensed_batches'] as List?) ?? [])
            .map((e) => DispensedBatch.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class DispensedBatch {
  final int batchId;
  final String batchNo;
  final String? expiryDate;
  final int quantity;

  const DispensedBatch({
    required this.batchId,
    required this.batchNo,
    this.expiryDate,
    required this.quantity,
  });

  factory DispensedBatch.fromJson(Map<String, dynamic> json) => DispensedBatch(
    batchId:    (json['batch_id'] as num).toInt(),
    batchNo:    json['batch_no'] as String? ?? '',
    expiryDate: json['expiry_date'] as String?,
    quantity:   (json['quantity'] as num).toInt(),
  );
}

class Prescription {
  final int prescriptionId;
  final String prescriptionDate;
  final String registerNo;
  final String patientName;
  final String gender;
  final int age;
  final String? address;
  final String? doctorName;
  final String? diagnosis;
  final String? note;
  final String status; // DISPENSED | CANCELLED
  final int itemCount;
  final List<PrescriptionItem> items;

  const Prescription({
    required this.prescriptionId,
    required this.prescriptionDate,
    required this.registerNo,
    required this.patientName,
    required this.gender,
    required this.age,
    this.address,
    this.doctorName,
    this.diagnosis,
    this.note,
    required this.status,
    this.itemCount = 0,
    this.items = const [],
  });

  bool get isCancelled => status == 'CANCELLED';

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
    prescriptionId:   _toInt(json['prescription_id']),
    prescriptionDate: json['prescription_date'] as String? ?? '',
    registerNo:       json['register_no'] as String? ?? '',
    patientName:      json['patient_name'] as String? ?? '',
    gender:           json['gender'] as String? ?? 'Other',
    age:              _toInt(json['age']),
    address:          json['address'] as String?,
    doctorName:       json['doctor_name'] as String?,
    diagnosis:        json['diagnosis'] as String?,
    note:             json['note'] as String?,
    status:           json['status'] as String? ?? 'DISPENSED',
    itemCount:        _toInt(json['item_count']),
    items:            ((json['items'] as List?) ?? [])
        .map((e) => PrescriptionItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class PrescriptionRequest {
  final String registerNo;
  final String patientName;
  final String gender; // Male | Female | Other
  final int age;
  final String? address;
  final String? doctorName;
  final String? diagnosis;
  final String? note;
  final List<PrescriptionItemRequest> items;

  const PrescriptionRequest({
    required this.registerNo,
    required this.patientName,
    required this.gender,
    required this.age,
    this.address,
    this.doctorName,
    this.diagnosis,
    this.note,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'register_no':  registerNo,
      'patient_name': patientName,
      'gender':       gender,
      'age':          age,
      'items':        items.map((e) => e.toJson()).toList(),
    };
    if (address   != null && address!.isNotEmpty)   map['address']   = address;
    if (doctorName!= null && doctorName!.isNotEmpty)map['doctor_name']= doctorName;
    if (diagnosis != null && diagnosis!.isNotEmpty) map['diagnosis'] = diagnosis;
    if (note      != null && note!.isNotEmpty)      map['note']      = note;
    return map;
  }
}

class PrescriptionItemRequest {
  final int medId;
  final int quantity;
  final String? dosageInstruction;
  final int? durationDays;

  const PrescriptionItemRequest({
    required this.medId,
    required this.quantity,
    this.dosageInstruction,
    this.durationDays,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'med_id':  medId,
      'quantity': quantity,
    };
    if (dosageInstruction != null && dosageInstruction!.isNotEmpty) {
      map['dosage_instruction'] = dosageInstruction;
    }
    if (durationDays != null) {
      map['duration_days'] = durationDays;
    }
    return map;
  }
}