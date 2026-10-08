import 'dart:ui';
import 'package:bloc/bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'localizations_event.dart';

class LocalizationBloc extends Bloc<LocalizationsEvent, Locale> {
  LocalizationBloc() : super(const Locale('en', 'US')) {
    on<LoadLocaleEvent>(_onLoadLocale);
    on<ChangeLocaleEvent>(_onChangeLocale);

    add(LoadLocaleEvent()); // Load saved locale on startup
  }

  Future<void> _onLoadLocale(
      LoadLocaleEvent event, Emitter<Locale> emit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('languageCode') ?? "en";
    String countryCode = prefs.getString('countryCode') ?? "US";

    emit(Locale(languageCode, countryCode.isNotEmpty ? countryCode : null));
  }

  Future<void> _onChangeLocale(
      ChangeLocaleEvent event, Emitter<Locale> emit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', event.locale.languageCode);
    await prefs.setString('countryCode', event.locale.countryCode ?? '');

    emit(event.locale);
  }
}
