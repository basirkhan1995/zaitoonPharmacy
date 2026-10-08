class MedicineReport {
  final String fromDate;
  final String toDate;
  final String? search;
  final int medicineCount;
  final int withMovements;
  final int grandTotalIn;
  final int grandTotalOut;
  final int grandBalance;
  final List<MedicineReportRow> medicines;

  const MedicineReport({
    required this.fromDate,
    required this.toDate,
    this.search,
    required this.medicineCount,
    required this.withMovements,
    required this.grandTotalIn,
    required this.grandTotalOut,
    required this.grandBalance,
    required this.medicines,
  });

  factory MedicineReport.fromJson(Map<String, dynamic> json) =>
      MedicineReport(
        fromDate:       json['from_date'] as String? ?? '',
        toDate:         json['to_date'] as String? ?? '',
        search:         json['search'] as String?,
        medicineCount:  (json['medicine_count'] as num?)?.toInt() ?? 0,
        withMovements:  (json['with_movements'] as num?)?.toInt() ?? 0,
        grandTotalIn:   (json['grand_total_in'] as num?)?.toInt() ?? 0,
        grandTotalOut:  (json['grand_total_out'] as num?)?.toInt() ?? 0,
        grandBalance:   (json['grand_balance'] as num?)?.toInt() ?? 0,
        medicines: ((json['medicines'] as List?) ?? [])
            .map((e) =>
            MedicineReportRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MedicineReportRow {
  final int medId;
  final String medName;
  final String unit;
  final String? dosage;
  final String? companyBrand;
  final String catName;
  final int totalIn;
  final int totalOut;
  final int balance;
  final String? organizations;

  const MedicineReportRow({
    required this.medId,
    required this.medName,
    required this.unit,
    this.dosage,
    this.companyBrand,
    required this.catName,
    required this.totalIn,
    required this.totalOut,
    required this.balance,
    this.organizations,
  });

  factory MedicineReportRow.fromJson(Map<String, dynamic> json) =>
      MedicineReportRow(
        medId:         (json['med_id'] as num).toInt(),
        medName:       json['med_name'] as String? ?? '',
        unit:          json['unit'] as String? ?? '',
        dosage:        json['dosage'] as String?,
        companyBrand:  json['company_brand'] as String?,
        catName:       json['cat_name'] as String? ?? '',
        totalIn:       (json['total_in'] as num?)?.toInt() ?? 0,
        totalOut:      (json['total_out'] as num?)?.toInt() ?? 0,
        balance:       (json['balance'] as num?)?.toInt() ?? 0,
        organizations: json['organizations'] as String?,
      );
}