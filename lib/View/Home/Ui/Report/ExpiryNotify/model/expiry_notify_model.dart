class ExpirySummary {
  final int expired;
  final int within3m;
  final int within6m;

  const ExpirySummary({
    required this.expired,
    required this.within3m,
    required this.within6m,
  });

  int get total => expired + within3m + within6m;
  bool get hasIssues => total > 0;

  factory ExpirySummary.fromJson(Map<String, dynamic> j) => ExpirySummary(
    expired:  (j['expired']   as num?)?.toInt() ?? 0,
    within3m: (j['within_3m'] as num?)?.toInt() ?? 0,
    within6m: (j['within_6m'] as num?)?.toInt() ?? 0,
  );
}