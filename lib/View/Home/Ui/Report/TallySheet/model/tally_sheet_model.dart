class TallyOut {
  final int movementId;
  final String type;
  final int quantity;   // negative
  final String date;    // YYYY-MM-DD

  const TallyOut({
    required this.movementId,
    required this.type,
    required this.quantity,
    required this.date,
  });

  factory TallyOut.fromJson(Map<String, dynamic> j) => TallyOut(
    movementId: (j['movement_id'] as num).toInt(),
    type:       (j['type'] ?? '').toString(),
    quantity:   (j['quantity'] as num).toInt(),
    date:       (j['date'] ?? '').toString(),
  );
}

class TallySheetRow {
  final int medId;
  final String medName;
  final String? dosage;
  final int catId;
  final String catName;
  final List<TallyOut> outs;
  final int total;

  const TallySheetRow({
    required this.medId,
    required this.medName,
    required this.dosage,
    required this.catId,
    required this.catName,
    required this.outs,
    required this.total,
  });

  factory TallySheetRow.fromJson(Map<String, dynamic> j) => TallySheetRow(
    medId:   (j['med_id'] as num).toInt(),
    medName: (j['med_name'] ?? '').toString(),
    dosage:  j['dosage']?.toString(),
    catId:   (j['cat_id'] as num).toInt(),
    catName: (j['cat_name'] ?? '').toString(),
    outs: (j['outs'] as List? ?? [])
        .map((e) => TallyOut.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: (j['total'] as num?)?.toInt() ?? 0,
  );
}