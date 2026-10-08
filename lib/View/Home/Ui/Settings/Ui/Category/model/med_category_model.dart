class Category {
  final int catId;
  final String catName;
  final String? catDetails;
  final int medicineCount;

  const Category({
    required this.catId,
    required this.catName,
    this.catDetails,
    this.medicineCount = 0,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    catId:         _toInt(json['cat_id']),
    catName:       json['cat_name'] as String,
    catDetails:    json['cat_details'] as String?,
    medicineCount: _toInt(json['medicine_count']),
  );

  Map<String, dynamic> toJson() => {
    'cat_id':         catId,
    'cat_name':       catName,
    'cat_details':    catDetails,
    'medicine_count': medicineCount,
  };

  Category copyWith({
    int? catId,
    String? catName,
    String? catDetails,
    int? medicineCount,
  }) => Category(
    catId:         catId ?? this.catId,
    catName:       catName ?? this.catName,
    catDetails:    catDetails ?? this.catDetails,
    medicineCount: medicineCount ?? this.medicineCount,
  );

  /// Handles int / double / numeric string (MySQL COUNT returns string).
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
class CategoryRequest {
  final String catName;
  final String? catDetails;

  const CategoryRequest({
    required this.catName,
    this.catDetails,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'cat_name': catName,
    };
    if (catDetails != null && catDetails!.isNotEmpty) {
      map['cat_details'] = catDetails;
    }
    return map;
  }

  factory CategoryRequest.fromCategory(Category c) => CategoryRequest(
    catName:    c.catName,
    catDetails: c.catDetails,
  );
}
