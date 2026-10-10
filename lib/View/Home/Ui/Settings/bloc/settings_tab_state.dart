part of 'settings_tab_bloc.dart';

enum SettingsTabName {system, users, category, backup, about}

final class SettingsTabState extends Equatable {
  final SettingsTabName tabs;
  const SettingsTabState({this.tabs = SettingsTabName.system});
  @override
  List<Object> get props => [tabs];
}





