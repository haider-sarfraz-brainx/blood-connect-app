import 'package:flutter/material.dart';

import '../../config/config.dart';
import '../../main.dart';

class Responsive {
  static BuildContext? get _context => navigatorKey.currentContext;

  static double w(double pixelWidth) {
    final ctx = _context;
    if (ctx == null) return pixelWidth;
    return (pixelWidth / Config.designScreenWidth) *
        MediaQuery.of(ctx).size.width;
  }

  static double h(double pixelHeight) {
    final ctx = _context;
    if (ctx == null) return pixelHeight;
    return (pixelHeight / Config.designScreenHeight) *
        MediaQuery.of(ctx).size.height;
  }

  static double f(double pixelWidth, {double breakpoint = 600.0}) {
    final ctx = _context;
    if (ctx == null) return pixelWidth;
    final screenWidth = MediaQuery.of(ctx).size.width;
    return (pixelWidth / Config.designScreenWidth) *
        (screenWidth > breakpoint ? breakpoint : screenWidth);
  }

  static double ws(double pixelWidth, {double startpoint = 480.0}) {
    final ctx = _context;
    if (ctx == null) return pixelWidth;
    final screenWidth = MediaQuery.of(ctx).size.width;
    return screenWidth <= startpoint
        ? pixelWidth
        : (pixelWidth / Config.designScreenWidth) * screenWidth;
  }

  static double hs(double pixelHeight, {double startpoint = 640.0}) {
    final ctx = _context;
    if (ctx == null) return pixelHeight;
    final screenHeight = MediaQuery.of(ctx).size.height;
    return screenHeight <= startpoint
        ? pixelHeight
        : (pixelHeight / Config.designScreenWidth) * screenHeight;
  }
}
