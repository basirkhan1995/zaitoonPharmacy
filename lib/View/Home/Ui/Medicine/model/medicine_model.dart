class Medicine {
  final int medId;
  final String medName;
  final String unit;
  final String? dosage;
  final String? companyBrand;
  final int catId;
  final String catName;
  final int availableStock;

  const Medicine({
    required this.medId,
    required this.medName,
    required this.unit,
    this.dosage,
    this.companyBrand,
    required this.catId,
    required this.catName,
    this.availableStock = 0,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
    medId:          (json['med_id'] as num).toInt(),
    medName:        json['med_name'] as String,
    unit:           json['unit'] as String,
    dosage:         json['dosage'] as String?,
    companyBrand:   json['company_brand'] as String?,
    catId:          (json['cat_id'] as num).toInt(),
    catName:        json['cat_name'] as String? ?? '',
    availableStock: (json['available_stock'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'med_id':          medId,
    'med_name':        medName,
    'unit':            unit,
    'dosage':          dosage,
    'company_brand':   companyBrand,
    'cat_id':          catId,
    'cat_name':        catName,
    'available_stock': availableStock,
  };

  Medicine copyWith({
    int? medId,
    String? medName,
    String? unit,
    String? dosage,
    String? companyBrand,
    int? catId,
    String? catName,
    int? availableStock,
  }) => Medicine(
    medId:          medId ?? this.medId,
    medName:        medName ?? this.medName,
    unit:           unit ?? this.unit,
    dosage:         dosage ?? this.dosage,
    companyBrand:   companyBrand ?? this.companyBrand,
    catId:          catId ?? this.catId,
    catName:        catName ?? this.catName,
    availableStock: availableStock ?? this.availableStock,
  );
}

class MedicineRequest {
  final String medName;
  final String unit;
  final String? dosage;
  final String? companyBrand;
  final int catId;

  const MedicineRequest({
    required this.medName,
    required this.unit,
    this.dosage,
    this.companyBrand,
    required this.catId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'med_name': medName,
      'unit':     unit,
      'cat_id':   catId,
    };
    if (dosage != null && dosage!.isNotEmpty)              map['dosage'] = dosage;
    if (companyBrand != null && companyBrand!.isNotEmpty)  map['company_brand'] = companyBrand;
    return map;
  }

  /// Build from an existing Medicine — for the update form.
  factory MedicineRequest.fromMedicine(Medicine m) => MedicineRequest(
    medName:      m.medName,
    unit:         m.unit,
    dosage:       m.dosage,
    companyBrand: m.companyBrand,
    catId:        m.catId,
  );
}