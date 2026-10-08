part of 'menu_bloc.dart';

sealed class MenuEvent extends Equatable {
  const MenuEvent();
}

class MenuOnChangedEvent extends MenuEvent{
  final MenuName name;
  const MenuOnChangedEvent(this.name);
  @override
  List<Object?> get props => [name];
}