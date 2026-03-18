import 'dart:ui';

extension ColorOpacityFix on Color {
  Color fixedOpacity(double opacity) {
    return withAlpha((opacity * 255).round());
  }
}