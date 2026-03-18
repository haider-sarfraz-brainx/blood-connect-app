
import 'package:equatable/equatable.dart';
import '../../config/theme/base.dart';

class ThemeState extends Equatable {
  final BaseTheme baseTheme;
  final String themeType;

  const ThemeState({
    required this.baseTheme,
    required this.themeType,
  });

  ThemeState copyWith({
    BaseTheme? baseTheme,
    String? themeType,
  }) {
    return ThemeState(
      baseTheme: baseTheme ?? this.baseTheme,
      themeType: themeType ?? this.themeType,
    );
  }

  @override
  List<Object?> get props => [baseTheme, themeType];
}
