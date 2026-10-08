import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'menu_event.dart';
part 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(MenuState(tabs: MenuName.dashboard)) {
    on<MenuOnChangedEvent>((event, emit) {
      emit(MenuState(tabs: event.name));
    });
  }

}
