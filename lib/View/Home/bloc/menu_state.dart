part of 'menu_bloc.dart';

enum MenuName {dashboard, prescription, medicine, stock, organization, staff, settings,report}

final class MenuState extends Equatable {
  final MenuName tabs;
  const MenuState({this.tabs = MenuName.dashboard});
  @override
  List<Object> get props => [tabs];
}

