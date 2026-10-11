class AntibioticReportRow {
  final String date;
  final int totalPrescriptions;
  final int antibioticPrescriptions;
  final int totalItems;
  final double antibioticPercent;
  final double polypharmacy;

  const AntibioticReportRow({
    required this.date,
    required this.totalPrescriptions,
    required this.antibioticPrescriptions,
    required this.totalItems,
    required this.antibioticPercent,
    required this.polypharmacy,
  });

  factory AntibioticReportRow.fromJson(Map<String, dynamic> j) =>
      AntibioticReportRow(
        date:                     j['date']?.toString() ?? '',
        totalPrescriptions:       (j['total_prescriptions']       as num?)?.toInt()    ?? 0,
        antibioticPrescriptions:  (j['antibiotic_prescriptions']  as num?)?.toInt()    ?? 0,
        totalItems:               (j['total_items']               as num?)?.toInt()    ?? 0,
        antibioticPercent:        (j['antibiotic_percent']        as num?)?.toDouble() ?? 0,
        polypharmacy:             (j['polypharmacy']              as num?)?.toDouble() ?? 0,
      );
}

class AntibioticReportTotals {
  final int totalPrescriptions;
  final int antibioticPrescriptions;
  final int totalItems;
  final double antibioticPercent;
  final double polypharmacy;

  const AntibioticReportTotals({
    required this.totalPrescriptions,
    required this.antibioticPrescriptions,
    required this.totalItems,
    required this.antibioticPercent,
    required this.polypharmacy,
  });

  factory AntibioticReportTotals.fromJson(Map<String, dynamic> j) =>
      AntibioticReportTotals(
        totalPrescriptions:       (j['total_prescriptions']       as num?)?.toInt()    ?? 0,
        antibioticPrescriptions:  (j['antibiotic_prescriptions']  as num?)?.toInt()    ?? 0,
        totalItems:               (j['total_items']               as num?)?.toInt()    ?? 0,
        antibioticPercent:        (j['antibiotic_percent']        as num?)?.toDouble() ?? 0,
        polypharmacy:             (j['polypharmacy']              as num?)?.toDouble() ?? 0,
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
    toDate:   j['to_date']   as String? ?? '',
    rows: (j['rows'] as List? ?? [])
        .map((e) => AntibioticReportRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    totals: AntibioticReportTotals.fromJson(
      (j['totals'] as Map<String, dynamic>?) ?? {},
    ),
  );
}