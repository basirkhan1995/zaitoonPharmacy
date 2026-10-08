part of 'localizations_bloc.dart';

sealed class LocalizationsEvent {}

class LoadLocaleEvent extends LocalizationsEvent {}

class ChangeLocaleEvent extends LocalizationsEvent {
  final Locale locale;

  ChangeLocaleEvent(this.locale);
}