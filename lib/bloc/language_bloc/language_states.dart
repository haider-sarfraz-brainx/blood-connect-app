
import 'package:equatable/equatable.dart';
import '../../config/languages/language.dart';

class LanguageState extends Equatable {
  final Language selectedLanguage;
  final List<Language> languages;
  final bool isLoading;

  const LanguageState({
    required this.selectedLanguage,
    required this.languages,
    this.isLoading = false,
  });

  LanguageState copyWith({
    Language? selectedLanguage,
    List<Language>? languages,
    bool? isLoading,
  }) {
    return LanguageState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      languages: languages ?? this.languages,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [selectedLanguage, languages, isLoading];
}
