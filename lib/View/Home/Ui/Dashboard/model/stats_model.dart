class TodayStats {
  final int prescriptions;
  final int medicinesOut;
  final int medicinesIn;
  final int antibioticItems;
  final double antibioticPercent;

  const TodayStats({
    required this.prescriptions,
    required this.medicinesOut,
    required this.medicinesIn,
    required this.antibioticItems,
    required this.antibioticPercent,
  });

  factory TodayStats.fromJson(Map<String, dynamic> j) => TodayStats(
    prescriptions:      (j['prescriptions']      as num?)?.toInt()    ?? 0,
    medicinesOut:       (j['medicines_out']      as num?)?.toInt()    ?? 0,
    medicinesIn:        (j['medicines_in']       as num?)?.toInt()    ?? 0,
    antibioticItems:    (j['antibiotic_items']   as num?)?.toInt()    ?? 0,
    antibioticPercent:  (j['antibiotic_percent'] as num?)?.toDouble() ?? 0,
  );
}

class InventoryStats {
  final int medicinesCatalog;
  final int activeBatches;
  final int unitsInStock;

  const InventoryStats({
    required this.medicinesCatalog,
    required this.activeBatches,
    required this.unitsInStock,
  });

  factory InventoryStats.fromJson(Map<String, dynamic> j) => InventoryStats(
    medicinesCatalog: (j['medicines_catalog'] as num?)?.toInt() ?? 0,
    activeBatches:    (j['active_batches']    as num?)?.toInt() ?? 0,
    unitsInStock:     (j['units_in_stock']    as num?)?.toInt() ?? 0,
  );
}

class DirectoryStats {
  final int organizations;
  final int staff;
  final int users;
  final int categories;

  const DirectoryStats({
    required this.organizations,
    required this.staff,
    required this.users,
    required this.categories,
  });

  factory DirectoryStats.fromJson(Map<String, dynamic> j) => DirectoryStats(
    organizations: (j['organizations'] as num?)?.toInt() ?? 0,
    staff:         (j['staff']         as num?)?.toInt() ?? 0,
    users:         (j['users']         as num?)?.toInt() ?? 0,
    categories:    (j['categories']    as num?)?.toInt() ?? 0,
  );
}

class ExpiryStats {
  final int expired;
  final int within3m;
  final int within6m;

  const ExpiryStats({
    required this.expired,
    required this.within3m,
    required this.within6m,
  });

  int get total => expired + within3m + within6m;

  factory ExpiryStats.fromJson(Map<String, dynamic> j) => ExpiryStats(
    expired:  (j['expired']   as num?)?.toInt() ?? 0,
    within3m: (j['within_3m'] as num?)?.toInt() ?? 0,
    within6m: (j['within_6m'] as num?)?.toInt() ?? 0,
  );
}

class DashboardStats {
  final TodayStats today;
  final InventoryStats inventory;
  final DirectoryStats directory;
  final ExpiryStats expiry;

  const DashboardStats({
    required this.today,
    required this.inventory,
    required this.directory,
    required this.expiry,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    today:     TodayStats.fromJson((j['today']     as Map?)?.cast<String, dynamic>() ?? {}),
    inventory: InventoryStats.fromJson((j['inventory'] as Map?)?.cast<String, dynamic>() ?? {}),
    directory: DirectoryStats.fromJson((j['directory'] as Map?)?.cast<String, dynamic>() ?? {}),
    expiry:    ExpiryStats.fromJson((j['expiry']    as Map?)?.cast<String, dynamic>() ?? {}),
  );
}