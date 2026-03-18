import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../config/config.dart';
import '../../config/languages/language_config.dart';
import '../../data/repositories/local/language.dart';
import '../../main.dart';
import 'language_events.dart';
import 'language_states.dart';


class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final LanguageRepo _languageRepo;

  LanguageBloc(this._languageRepo)
      : super(LanguageState(
    selectedLanguage: LanguageConfig.defaultLanguage(Config.english),
    languages: LanguageConfig.languages,
  )) {
    on<LoadLanguage>(_onLoadLanguage);
    on<SetLanguage>(_onSetLanguage);
  }

  Future<void> _onLoadLanguage(
      LoadLanguage event, Emitter<LanguageState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final savedLanguage = _languageRepo.getLanguage();
      emit(state.copyWith(
        selectedLanguage: savedLanguage,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(
        selectedLanguage: LanguageConfig.defaultLanguage(Config.english),
        isLoading: false,
      ));
    }
  }

  Future<void> _onSetLanguage(
      SetLanguage event, Emitter<LanguageState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await navigatorKey.currentContext?.setLocale(event.language.locale);
      await _languageRepo.setLanguage(language: event.language);
      emit(state.copyWith(
        selectedLanguage: event.language,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint("Error setting language: $e");
      emit(state.copyWith(isLoading: false));
    }
  }
}

