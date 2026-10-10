// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello_world => 'Hi! You set up intl!';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get systemMode => 'System';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectYear => 'Select year';

  @override
  String get selectKeyword => 'Select';

  @override
  String get today => 'Today';

  @override
  String get selectDate => 'Select Date';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get lastweek => 'Last week';

  @override
  String get lastMonth => 'Last month';

  @override
  String get allTime => 'All time';

  @override
  String get thisYear => 'This year';

  @override
  String get lastYear => 'Last year';

  @override
  String get lastThreeMonth => 'Last 90 Days';

  @override
  String get thisMonth => 'This month';

  @override
  String get current => 'Current';

  @override
  String get loginTitle => 'Login';

  @override
  String get usrName => 'Username';

  @override
  String get usrPass => 'Password';

  @override
  String required(String name) {
    return '$name is required';
  }

  @override
  String get rememberMe => 'Remember me';

  @override
  String get logout => 'Logout';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get settings => 'Settings';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get prescription => 'Prescription';

  @override
  String get medicine => 'Medicine';

  @override
  String get report => 'Report';

  @override
  String get organization => 'Organization';

  @override
  String get update => 'Update';

  @override
  String get create => 'Create';

  @override
  String get editMedicine => 'Edit Medicine';

  @override
  String get newMedicine => 'New Medicine';

  @override
  String get medicineName => 'Medicine name';

  @override
  String get unit => 'Unit';

  @override
  String get dosage => 'Dosage';

  @override
  String get brand => 'Brand';

  @override
  String get category => 'Medicine Category';

  @override
  String get selectCategory => 'Select category';

  @override
  String get successTitle => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get noStock => 'Out of stock';

  @override
  String get dispense => 'Dispense';

  @override
  String get stock => 'Stock';

  @override
  String get patient => 'Patient';

  @override
  String get regNo => 'Register No';

  @override
  String get patientName => 'Patient name';

  @override
  String get age => 'Age';

  @override
  String get days => 'Days';

  @override
  String get instruction => 'Instruction';

  @override
  String get qty => 'Qty';

  @override
  String get prescriptions => 'Prescriptions';

  @override
  String get noPrescriptionToday => 'No prescription for today';

  @override
  String get systemSettings => 'System';
}
