class StockCardReport {
  final Map<String, dynamic> medicine;
  final String fromDate;
  final String toDate;
  final int openingBalance;
  final int totalIn;
  final int totalOut;
  final int closingBalance;
  final List<StockCardRow> movements;

  const StockCardReport({
    required this.medicine,
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.totalIn,
    required this.totalOut,
    required this.closingBalance,
    required this.movements,
  });

  factory StockCardReport.fromJson(Map<String, dynamic> json) =>
      StockCardReport(
        medicine:       json['medicine'] as Map<String, dynamic>? ?? {},
        fromDate:       json['from_date'] as String? ?? '',
        toDate:         json['to_date'] as String? ?? '',
        openingBalance: (json['opening_balance'] as num?)?.toInt() ?? 0,
        totalIn:        (json['total_in'] as num?)?.toInt() ?? 0,
        totalOut:       (json['total_out'] as num?)?.toInt() ?? 0,
        closingBalance: (json['closing_balance'] as num?)?.toInt() ?? 0,
        movements: ((json['movements'] as List?) ?? [])
            .map((e) => StockCardRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StockCardRow {
  final int movementId;
  final String date;
  final String type;
  final int inQty;
  final int outQty;
  final int balance;
  final String? batchNo;
  final String? expiryDate;
  final String? orgName;
  final String? receiver;
  final String? reference;
  final String? patientName;
  final String? note;

  const StockCardRow({
    required this.movementId,
    required this.date,
    required this.type,
    required this.inQty,
    required this.outQty,
    required this.balance,
    this.batchNo,
    this.expiryDate,
    this.orgName,
    this.receiver,
    this.reference,
    this.patientName,
    this.note,
  });

  factory StockCardRow.fromJson(Map<String, dynamic> json) => StockCardRow(
    movementId:  (json['movement_id'] as num).toInt(),
    date:        _dateOnly(json['date']),
    type:        json['type'] as String? ?? '',
    inQty:       (json['in_qty'] as num?)?.toInt() ?? 0,
    outQty:      (json['out_qty'] as num?)?.toInt() ?? 0,
    balance:     (json['balance'] as num?)?.toInt() ?? 0,
    batchNo:     json['batch_no'] as String?,
    expiryDate:  json['expiry_date'] == null
        ? null
        : _dateOnly(json['expiry_date']),
    orgName:     json['org_name'] as String?,
    receiver:    json['receiver'] as String?,
    reference:   json['reference'] as String?,
    patientName: json['patient_name'] as String?,
    note:        json['note'] as String?,
  );

  static String _dateOnly(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}