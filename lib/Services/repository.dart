import 'package:dio/dio.dart';
import 'package:zpharmacy/View/Auth/auth_model.dart';
import '../View/Home/Ui/Medicine/model/medicine_model.dart';
import '../View/Home/Ui/Organization/model/org_model.dart';
import '../View/Home/Ui/Prescription/model/prescription_model.dart';
import '../View/Home/Ui/Settings/Ui/Category/model/med_category_model.dart';
import 'api_services.dart';

class Repositories {
  final ApiServices _api;
  const Repositories(this._api);
  bool get isLoggedIn => _api.isLoggedIn;

  Future<AuthResponse> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    final data = await _api.post(
      '/api/auth/login',
      data: {
    'username': username,
    'password': password,
    });

    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await _api.setToken(auth.token, persist: rememberMe);
    return auth;
  }

  Future<AuthResponse> register(RegisterRequest req) async {
    final data = await _api.post('/api/auth/register', data: req.toJson());
    final auth = AuthResponse.fromJson(data as Map<String, dynamic>);
    await _api.setToken(auth.token, persist: true);
    return auth;
  }

  Future<User> me() async {
    final data = await _api.get('/api/auth/me');
    return User.fromJson(data as Map<String, dynamic>);
  }

  Future<void> logout() => _api.logout();


  // =================================================================
  // MEDICINE
  // =================================================================

  Future<List<Medicine>> getMedicines({String? search}) async {
    final data = await _api.get(
      '/api/medicines',
      queryParams: (search != null && search.isNotEmpty)
          ? {'search': search}
          : null,
    );
    return (data as List)
        .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Medicine> getMedicine(int medId) async {
    final data = await _api.get('/api/medicines/$medId');
    return Medicine.fromJson(data as Map<String, dynamic>);
  }

  Future<Medicine> createMedicine(MedicineRequest req) async {
    final data = await _api.post('/api/medicines', data: req.toJson());
    final id = (data['med_id'] as num).toInt();
    return getMedicine(id);
  }

  Future<Medicine> updateMedicine(int medId, MedicineRequest req) async {
    await _api.put('/api/medicines/$medId', data: req.toJson());
    return getMedicine(medId);
  }

  Future<void> deleteMedicine(int medId) async {
    await _api.delete('/api/medicines/$medId');
  }


// =================================================================
// CATEGORY
// =================================================================

Future<List<Category>> getCategories() async {
  final data = await _api.get('/api/categories');
  return (data as List)
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<Category> getCategory(int catId) async {
  final data = await _api.get('/api/categories/$catId');
  return Category.fromJson(data as Map<String, dynamic>);
}

Future<Category> createCategory(CategoryRequest req) async {
  final data = await _api.post('/api/categories', data: req.toJson());
  final id = (data['cat_id'] as num).toInt();
  return getCategory(id);
}

Future<Category> updateCategory(int catId, CategoryRequest req) async {
  await _api.put('/api/categories/$catId', data: req.toJson());
  return getCategory(catId);
}

Future<void> deleteCategory(int catId) async {
  await _api.delete('/api/categories/$catId');
}

// =================================================================
// ORGANIZATION
// =================================================================

  Future<List<Organization>> getOrganizations() async {
    final data = await _api.get('/api/organizations');
    return (data as List)
        .map((e) => Organization.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Organization> getOrganization(int orgId) async {
    final data = await _api.get('/api/organizations/$orgId');
    return Organization.fromJson(data as Map<String, dynamic>);
  }

  /// Builds a FormData request (multipart) so the logo file can be sent.
  FormData _orgFormData(OrganizationRequest req) {
    final map = <String, dynamic>{...req.toFields()};
    if (req.logo != null) {
      map['logo'] = MultipartFile.fromFileSync(
        req.logo!.path,
        filename: req.logo!.uri.pathSegments.last,
      );
    }
    return FormData.fromMap(map);
  }

  Future<Organization> createOrganization(OrganizationRequest req) async {
    final data = await _api.uploadFile(
      '/api/organizations',
      data: _orgFormData(req),
    );
    final id = (data['org_id'] as num).toInt();
    return getOrganization(id);
  }


  Future<Organization> updateOrganization(
      int orgId, OrganizationRequest req) async {
    await _api.uploadFile(
      '/api/organizations/$orgId',
      data: _orgFormData(req),
    );
    return getOrganization(orgId);
  }

  Future<void> deleteOrganization(int orgId) async {
    await _api.delete('/api/organizations/$orgId');
  }

  Future<void> deleteOrganizationLogo(int orgId) async {
    await _api.delete('/api/organizations/$orgId/logo');
  }

  // =================================================================
// PRESCRIPTION
// =================================================================

  Future<List<Prescription>> getPrescriptions() async {
    final data = await _api.get('/api/prescriptions');
    return (data as List)
        .map((e) => Prescription.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Prescription> getPrescription(int id) async {
    final data = await _api.get('/api/prescriptions/$id');
    return Prescription.fromJson(data as Map<String, dynamic>);
  }

  /// Creates the prescription AND dispenses stock in one transaction.
  /// Returns the new prescription's ID.
  Future<Prescription> createPrescription(PrescriptionRequest req) async {
    final data = await _api.post('/api/prescriptions', data: req.toJson());
    final id = (data['prescription_id'] as num).toInt();
    return getPrescription(id);
  }

  Future<Prescription> updatePrescription(
      int id, PrescriptionRequest req) async {
    // Send only the header fields; items are ignored by the server
    await _api.put('/api/prescriptions/$id', data: {
      'register_no':  req.registerNo,
      'patient_name': req.patientName,
      'gender':       req.gender,
      'age':          req.age,
      if (req.address    != null) 'address':     req.address,
      if (req.doctorName != null) 'doctor_name': req.doctorName,
      if (req.diagnosis  != null) 'diagnosis':   req.diagnosis,
      if (req.note       != null) 'note':        req.note,
    });
    return getPrescription(id);
  }
  Future<void> cancelPrescription(int id) async {
    await _api.delete('/api/prescriptions/$id');
  }

}