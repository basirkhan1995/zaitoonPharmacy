import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'themes_event.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeMode> {
  ThemeBloc() : super(ThemeMode.system) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ChangeThemeEvent>(_onChangeTheme);

    add(LoadThemeEvent()); // Load on initialization
  }

  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeMode> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    String? savedTheme = prefs.getString('themeMode');
    switch (savedTheme) {
      case 'light':
        emit(ThemeMode.light);
        break;
      case 'dark':
        emit(ThemeMode.dark);
        break;
      case 'system':
      default:
        emit(ThemeMode.system);
        break;
    }
  }

  Future<void> _onChangeTheme(
    ChangeThemeEvent event,
    Emitter<ThemeMode> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', event.mode);

    switch (event.mode) {
      case 'light':
        emit(ThemeMode.light);
        break;
      case 'dark':
        emit(ThemeMode.dark);
        break;
      case 'system':
      default:
        emit(ThemeMode.system);
        break;
    }
  }
}
