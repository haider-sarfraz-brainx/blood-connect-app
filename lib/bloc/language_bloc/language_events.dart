
import 'package:equatable/equatable.dart';
import '../../config/languages/language.dart';

abstract class LanguageEvent extends Equatable {
  const LanguageEvent();

  @override
  List<Object?> get props => [];
}

class LoadLanguage extends LanguageEvent {}

class SetLanguage extends LanguageEvent {
  final Language language;

  const SetLanguage(this.language);

  @override
  List<Object?> get props => [language];
}
