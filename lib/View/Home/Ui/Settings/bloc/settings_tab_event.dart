part of 'settings_tab_bloc.dart';

sealed class SettingsTabEvent extends Equatable {
  const SettingsTabEvent();
}

class SettingsOnChangeEvent extends SettingsTabEvent{
  final SettingsTabName tab;
  const SettingsOnChangeEvent(this.tab);
  @override
  List<Object?> get props => [tab];
}