class AntibioticReportRow {
  final String date;
  final int totalMedicines;
  final int totalPrescriptions;
  final int antibioticCount;
  final double antibioticPercent;
  final int polypharmacyCount;
  final double polypharmacyPercent;

  const AntibioticReportRow({
    required this.date,
    required this.totalMedicines,
    required this.totalPrescriptions,
    required this.antibioticCount,
    required this.antibioticPercent,
    required this.polypharmacyCount,
    required this.polypharmacyPercent,
  });

  factory AntibioticReportRow.fromJson(Map<String, dynamic> j) =>
      AntibioticReportRow(
        date:                 j['date']?.toString() ?? '',
        totalMedicines:       (j['total_medicines'] as num?)?.toInt() ?? 0,
        totalPrescriptions:   (j['total_prescriptions'] as num?)?.toInt() ?? 0,
        antibioticCount:      (j['antibiotic_count'] as num?)?.toInt() ?? 0,
        antibioticPercent:    (j['antibiotic_percent'] as num?)?.toDouble() ?? 0,
        polypharmacyCount:    (j['polypharmacy_count'] as num?)?.toInt() ?? 0,
        polypharmacyPercent:  (j['polypharmacy_percent'] as num?)?.toDouble() ?? 0,
      );
}

class AntibioticReportTotals {
  final int totalMedicines;
  final int totalPrescriptions;
  final int antibioticCount;
  final double antibioticPercent;
  final int polypharmacyCount;
  final double polypharmacyPercent;

  const AntibioticReportTotals({
    required this.totalMedicines,
    required this.totalPrescriptions,
    required this.antibioticCount,
    required this.antibioticPercent,
    required this.polypharmacyCount,
    required this.polypharmacyPercent,
  });

  factory AntibioticReportTotals.fromJson(Map<String, dynamic> j) =>
      AntibioticReportTotals(
        totalMedicines:       (j['total_medicines'] as num?)?.toInt() ?? 0,
        totalPrescriptions:   (j['total_prescriptions'] as num?)?.toInt() ?? 0,
        antibioticCount:      (j['antibiotic_count'] as num?)?.toInt() ?? 0,
        antibioticPercent:    (j['antibiotic_percent'] as num?)?.toDouble() ?? 0,
        polypharmacyCount:    (j['polypharmacy_count'] as num?)?.toInt() ?? 0,
        polypharmacyPercent:  (j['polypharmacy_percent'] as num?)?.toDouble() ?? 0,
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