import 'package:flutter/material.dart';

abstract class BaseTheme {
  Color get primary;
  Color get background;
  Color get textColor;
  Color get white;
  Color get disable;
  Color get shimmer;
  Color get yellow;

  SettingsColors get settings;
  BottomNavBarColors get bottomNavBar;

  ThemeData get themeData;
}

abstract class SettingsColors {
  Color get iconBackground;
  Color get icon;
  Color get tileTitle;
  Color get switchThumb;
}

abstract class BottomNavBarColors {
  Color get foreground;
  Color get background;
  Color get indicator;
  Color get surface;
}
