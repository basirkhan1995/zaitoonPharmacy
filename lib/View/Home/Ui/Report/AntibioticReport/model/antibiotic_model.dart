class AntibioticReportRow {
  final String date;
  final int totalPrescriptions;
  final int totalItems;         // prescription_item rows
  final int totalMedicines;     // SUM(quantity)
  final int antibioticItems;    // antibiotic prescription_item rows
  final int antibioticMedicines;// SUM(quantity) for antibiotic items
  final double antibioticPercent;
  final double polypharmacyPercent;

  const AntibioticReportRow({
    required this.date,
    required this.totalPrescriptions,
    required this.totalItems,
    required this.totalMedicines,
    required this.antibioticItems,
    required this.antibioticMedicines,
    required this.antibioticPercent,
    required this.polypharmacyPercent,
  });

  factory AntibioticReportRow.fromJson(Map<String, dynamic> j) =>
      AntibioticReportRow(
        date:                 j['date']?.toString() ?? '',
        totalPrescriptions:   (j['total_prescriptions'] as num?)?.toInt() ?? 0,
        totalItems:           (j['total_items']         as num?)?.toInt() ?? 0,
        totalMedicines:       (j['total_medicines']     as num?)?.toInt() ?? 0,
        antibioticItems:      (j['antibiotic_items']    as num?)?.toInt() ?? 0,
        antibioticMedicines:  (j['antibiotic_medicines']as num?)?.toInt() ?? 0,
        antibioticPercent:    (j['antibiotic_percent']  as num?)?.toDouble() ?? 0,
        polypharmacyPercent:  (j['polypharmacy_percent']as num?)?.toDouble() ?? 0,
      );
}

class AntibioticReportTotals {
  final int totalPrescriptions;
  final int totalItems;
  final int totalMedicines;
  final int antibioticItems;
  final int antibioticMedicines;
  final double antibioticPercent;
  final double polypharmacyPercent;

  const AntibioticReportTotals({
    required this.totalPrescriptions,
    required this.totalItems,
    required this.totalMedicines,
    required this.antibioticItems,
    required this.antibioticMedicines,
    required this.antibioticPercent,
    required this.polypharmacyPercent,
  });

  factory AntibioticReportTotals.fromJson(Map<String, dynamic> j) =>
      AntibioticReportTotals(
        totalPrescriptions:   (j['total_prescriptions'] as num?)?.toInt() ?? 0,
        totalItems:           (j['total_items']         as num?)?.toInt() ?? 0,
        totalMedicines:       (j['total_medicines']     as num?)?.toInt() ?? 0,
        antibioticItems:      (j['antibiotic_items']    as num?)?.toInt() ?? 0,
        antibioticMedicines:  (j['antibiotic_medicines']as num?)?.toInt() ?? 0,
        antibioticPercent:    (j['antibiotic_percent']  as num?)?.toDouble() ?? 0,
        polypharmacyPercent:  (j['polypharmacy_percent']as num?)?.toDouble() ?? 0,
      );
}

class AntibioticReport {
  final String fromDate;
  final String toDate;
  final List<AntibioticReportRow> rows;
  final AntibioticReportTotals totals;

  const AntibioticReport({
    required this.fromDate,
    required this.toDate,
    required this.rows,
    required this.totals,
  });

  factory AntibioticReport.fromJson(Map<String, dynamic> j) => AntibioticReport(
    fromDate: j['from_date'] as String? ?? '',
    toDate:   j['to_date'] as String? ?? '',
    rows: (j['rows'] as List? ?? [])
        .map((e) => AntibioticReportRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    totals: AntibioticReportTotals.fromJson(
      (j['totals'] as Map<String, dynamic>?) ?? {},
    ),
  );
}