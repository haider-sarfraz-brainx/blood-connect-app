import 'package:flutter/material.dart';
import '../../core/extensions/color.dart';
import '../config.dart';
import 'base.dart';

class DarkTheme implements BaseTheme {
  @override
  final Color primary = const Color(0xFFC81D4D);
  @override
  final Color background = const Color(0xFFFFFFFF);
  @override
  final Color textColor = const Color(0xFF000000);
  @override
  final Color white = const Color(0xFFFFFFFF);
  @override
  final Color disable = const Color(0xFF808080);
  @override
  final Color shimmer = const Color(0xFFB5B2B2);

  @override
  final SettingsColors settings = SettingsColorsImpl();
  @override
  final BottomNavBarColors bottomNavBar = BottomNavBarColorsImpl();

  @override
  late final ThemeData themeData = ThemeData(
      fontFamily: Config.fontMontserratFamily,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: primary));
}

class SettingsColorsImpl implements SettingsColors {
  @override
  final iconBackground = const Color(0xFF485166).fixedOpacity(0.32);
  @override
  final icon = const Color(0xFF98A6A0);

  @override
  Color get tileTitle => const Color(0xFFEEEEEF);

  @override
  Color get switchThumb => const Color(0xFF333836);
}

class BottomNavBarColorsImpl implements BottomNavBarColors {
  @override
  Color get background => const Color(0xFFFFFFFF).fixedOpacity(0.7);
  @override
  Color get foreground => const Color(0xFFAE5005);
  @override
  Color get indicator => const Color(0xFF808080);
  @override
  Color get surface => const Color(0xFFFFFFFF);
}
