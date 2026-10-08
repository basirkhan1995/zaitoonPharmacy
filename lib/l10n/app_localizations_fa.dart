// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get hello_world => 'سلام، همه چیز آمده است';

  @override
  String get lightMode => 'روشنایی';

  @override
  String get darkMode => 'تاریکی';

  @override
  String get systemMode => 'سیستم';

  @override
  String get cancel => 'لغو کردن';

  @override
  String get save => 'ثبت کردن';

  @override
  String get selectAll => 'انتخاب همه';

  @override
  String get selectYear => 'انتخاب سال';

  @override
  String get selectKeyword => 'انتخاب';

  @override
  String get today => 'امروز';

  @override
  String get selectDate => 'انتخاب تاریخ';

  @override
  String get yesterday => 'دیروز';

  @override
  String get lastweek => 'هفته گذشته';

  @override
  String get lastMonth => 'ماه گذشته';

  @override
  String get allTime => 'همه وقت';

  @override
  String get thisYear => 'امسال';

  @override
  String get lastYear => 'سال گذشته';

  @override
  String get lastThreeMonth => 'سه ماه گذشته';

  @override
  String get thisMonth => 'این ماه';

  @override
  String get current => 'فعلی';

  @override
  String get loginTitle => 'ورود';

  @override
  String get usrName => 'حساب کاربر';

  @override
  String get usrPass => 'رمز عبور';

  @override
  String required(String name) {
    return ' الزامی است $name';
  }

  @override
  String get rememberMe => 'مرا بخاطر بسپار';

  @override
  String get logout => 'خروج';

  @override
  String get accessDenied => 'دسترسی غیرمجاز';

  @override
  String get confirmLogout => 'آیا میخواهید از برنامه خارج شوید؟';

  @override
  String get settings => 'تنظیمات';

  @override
  String get dashboard => 'داشبورد';

  @override
  String get prescription => 'نسخه';

  @override
  String get medicine => 'ادویه ها';

  @override
  String get report => 'راپور ها';

  @override
  String get organization => 'سازمان';

  @override
  String get update => 'بروزرسانی';

  @override
  String get create => 'ثبت کردن';

  @override
  String get editMedicine => 'بروزرسانی ادویه';

  @override
  String get newMedicine => 'ثبت ادویه';

  @override
  String get medicineName => 'نام دوا';

  @override
  String get unit => 'واحد';

  @override
  String get dosage => 'مقدار مصرف';

  @override
  String get brand => 'برند یا کمپنی';

  @override
  String get category => 'کتگوری دوا';

  @override
  String get selectCategory => 'انتخاب کتگوری';

  @override
  String get successTitle => 'موفقانه';

  @override
  String get failed => 'ناموفق';

  @override
  String get noStock => 'ناموجود';

  @override
  String get dispense => 'تجویز کردن';

  @override
  String get stock => 'سهام';

  @override
  String get patient => 'مریض';

  @override
  String get regNo => 'نمبر راجستر';

  @override
  String get patientName => 'نام مریض';

  @override
  String get age => 'سن';

  @override
  String get days => 'روز';

  @override
  String get instruction => 'راهنمایی دوا';

  @override
  String get qty => 'تعداد';
}
