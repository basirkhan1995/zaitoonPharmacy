import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'settings_tab_event.dart';
part 'settings_tab_state.dart';

class SettingsTabBloc extends Bloc<SettingsTabEvent, SettingsTabState> {
  SettingsTabBloc() : super(SettingsTabState(tabs: SettingsTabName.system)) {
    on<SettingsOnChangeEvent>((event, emit) {
      emit(SettingsTabState(tabs: event.tab));
    });

  }
}
