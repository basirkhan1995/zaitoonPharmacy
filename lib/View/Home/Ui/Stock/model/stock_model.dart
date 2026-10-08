class StockInvoice {
  final int invoiceId;
  final String invoiceNo;
  final String invoiceDate;
  final String movementType;
  final int? orgId;
  final String? orgName;
  final String? note;
  final int itemCount;
  final int totalQty;
  final List<StockInvoiceItem> items;

  const StockInvoice({
    required this.invoiceId,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.movementType,
    this.orgId,
    this.orgName,
    this.note,
    this.itemCount = 0,
    this.totalQty = 0,
    this.items = const [],
  });

  bool get isInbound =>
      movementType == 'RECEIVE' || movementType == 'DONATION_IN';
  bool get isOutbound =>
      movementType == 'DONATION_OUT' ||
          movementType == 'EXPIRED' ||
          movementType == 'DAMAGE';
  bool get isAdjustment => movementType == 'ADJUSTMENT';

  factory StockInvoice.fromJson(Map<String, dynamic> json) => StockInvoice(
    invoiceId:    _toInt(json['invoice_id']),
    invoiceNo:    json['invoice_no'] as String? ?? '',
    invoiceDate:  _dateOnly(json['invoice_date']),
    movementType: json['movement_type'] as String? ?? 'RECEIVE',
    orgId:        json['org_id'] == null ? null : _toInt(json['org_id']),
    orgName:      json['org_name'] as String?,
    note:         json['note'] as String?,
    itemCount:    _toInt(json['item_count']),
    totalQty:     _toInt(json['total_qty']),
    items:        ((json['items'] as List?) ?? [])
        .map((e) => StockInvoiceItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _dateOnly(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class StockInvoiceItem {
  final int? movementId;
  final int? batchId;
  final int? medId;
  final String? medName;
  final String? unit;
  final String? dosage;
  final String? companyBrand;
  final String? batchNo;
  final String? expiryDate;
  final int quantity;
  final int? quantityReceived;
  final int? quantityRemaining;
  final String? batchStatus;
  final String? note;

  const StockInvoiceItem({
    this.movementId,
    this.batchId,
    this.medId,
    this.medName,
    this.unit,
    this.dosage,
    this.companyBrand,
    this.batchNo,
    this.expiryDate,
    required this.quantity,
    this.quantityReceived,
    this.quantityRemaining,
    this.batchStatus,
    this.note,
  });

  factory StockInvoiceItem.fromJson(Map<String, dynamic> json) =>
      StockInvoiceItem(
        movementId:        json['movement_id'] == null ? null : _toInt(json['movement_id']),
        batchId:           json['batch_id'] == null ? null : _toInt(json['batch_id']),
        medId:             json['med_id'] == null ? null : _toInt(json['med_id']),
        medName:           json['med_name'] as String?,
        unit:              json['unit'] as String?,
        dosage:            json['dosage'] as String?,
        companyBrand:      json['company_brand'] as String?,
        batchNo:           json['batch_no'] as String?,
        expiryDate:        json['expiry_date'] == null ? null : _dateOnly(json['expiry_date']),
        quantity:          _toInt(json['quantity']),
        quantityReceived:  json['quantity_received'] == null ? null : _toInt(json['quantity_received']),
        quantityRemaining: json['quantity_remaining'] == null ? null : _toInt(json['quantity_remaining']),
        batchStatus:       json['batch_status'] as String?,
        note:              json['note'] as String?,
      );

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static String _dateOnly(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}

class StockInvoiceRequest {
  final String invoiceNo;
  final String invoiceDate;
  final String movementType;
  final int? orgId;
  final String? note;
  final List<StockInvoiceItemRequest> items;

  const StockInvoiceRequest({
    required this.invoiceNo,
    required this.invoiceDate,
    required this.movementType,
    this.orgId,
    this.note,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'invoice_no':    invoiceNo,
      'invoice_date':  invoiceDate,
      'movement_type': movementType,
      'items':         items.map((e) => e.toJson()).toList(),
    };
    if (orgId != null) m['org_id'] = orgId;
    if (note != null && note!.isNotEmpty) m['note'] = note;
    return m;
  }
}

class StockInvoiceItemRequest {
  final int? medId;
  final String? batchNo;
  final String? expiryDate;
  final int? batchId;
  final int quantity;
  final String? note;

  const StockInvoiceItemRequest({
    this.medId,
    this.batchNo,
    this.expiryDate,
    this.batchId,
    required this.quantity,
    this.note,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'quantity': quantity};
    if (medId      != null) m['med_id']      = medId;
    if (batchNo    != null) m['batch_no']    = batchNo;
    if (expiryDate != null) m['expiry_date'] = expiryDate;
    if (batchId    != null) m['batch_id']    = batchId;
    if (note != null && note!.isNotEmpty) m['note'] = note;
    return m;
  }
}

class StockBatchOption {
  final int batchId;
  final int medId;
  final String medName;
  final String? unit;
  final String? dosage;
  final String batchNo;
  final String expiryDate;
  final int quantityRemaining;

  const StockBatchOption({
    required this.batchId,
    required this.medId,
    required this.medName,
    this.unit,
    this.dosage,
    required this.batchNo,
    required this.expiryDate,
    required this.quantityRemaining,
  });
}