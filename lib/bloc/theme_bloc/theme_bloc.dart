import 'package:bloc/bloc.dart';
import 'package:training_projects/bloc/theme_bloc/theme_events.dart';
import 'package:training_projects/bloc/theme_bloc/theme_states.dart';
import '../../config/config.dart';
import '../../config/theme/dark.dart';
import '../../config/theme/light.dart';
import '../../data/repositories/local/theme.dart';


class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepo _themeRepo;

  ThemeBloc(this._themeRepo)
      : super(
    ThemeState(
      baseTheme: _themeRepo.getTheme() == Config.dark
          ? DarkTheme()
          : LightTheme(),
      themeType: _themeRepo.getTheme(),
    ),
  ) {
    on<SetTheme>(_onSetTheme);
  }

  Future<void> _onSetTheme(SetTheme event, Emitter<ThemeState> emit) async {
    if (event.theme == state.themeType) return;

    _themeRepo.setTheme(theme: event.theme);

    emit(
      state.copyWith(
        themeType: event.theme,
        baseTheme: event.theme == Config.dark ? DarkTheme() : LightTheme(),
      ),
    );
  }
}
