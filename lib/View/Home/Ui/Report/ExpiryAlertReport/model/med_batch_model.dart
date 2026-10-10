class ExpiryAlertRow {
  final int batchId;
  final String batchNo;
  final String expiryDate;
  final String receivedDate;
  final int quantityReceived;
  final int quantityRemaining;
  final String status;
  final int daysLeft;
  final int medId;
  final String medName;
  final String unit;
  final String? dosage;
  final String catName;
  final String? orgName;

  const ExpiryAlertRow({
    required this.batchId,
    required this.batchNo,
    required this.expiryDate,
    required this.receivedDate,
    required this.quantityReceived,
    required this.quantityRemaining,
    required this.status,
    required this.daysLeft,
    required this.medId,
    required this.medName,
    required this.unit,
    this.dosage,
    required this.catName,
    this.orgName,
  });

  factory ExpiryAlertRow.fromJson(Map<String, dynamic> j) => ExpiryAlertRow(
    batchId:           (j['batch_id'] as num?)?.toInt() ?? 0,
    batchNo:           j['batch_no']?.toString() ?? '',
    expiryDate:        _dateOnly(j['expiry_date']),
    receivedDate:      _dateOnly(j['received_date']),
    quantityReceived:  (j['quantity_received'] as num?)?.toInt() ?? 0,
    quantityRemaining: (j['quantity_remaining'] as num?)?.toInt() ?? 0,
    status:            j['status']?.toString() ?? 'ACTIVE',
    daysLeft:          (j['days_left'] as num?)?.toInt() ?? 0,
    medId:             (j['med_id'] as num?)?.toInt() ?? 0,
    medName:           j['med_name']?.toString() ?? '',
    unit:              j['unit']?.toString() ?? '',
    dosage:            j['dosage']?.toString(),
    catName:           j['cat_name']?.toString() ?? '',
    orgName:           j['org_name']?.toString(),
  );

  static String _dateOnly(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class ExpiryAlertReport {
  final String? fromDate;
  final String? toDate;
  final bool onlyExpiring;
  final List<ExpiryAlertRow> rows;

  const ExpiryAlertReport({
    this.fromDate,
    this.toDate,
    required this.onlyExpiring,
    required this.rows,
  });

  factory ExpiryAlertReport.fromJson(Map<String, dynamic> j) => ExpiryAlertReport(
    fromDate:     j['from_date']?.toString(),
    toDate:       j['to_date']?.toString(),
    onlyExpiring: j['only_expiring'] != false,
    rows: (j['rows'] as List? ?? [])
        .map((e) => ExpiryAlertRow.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}