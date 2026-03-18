import 'package:flutter/material.dart';
import '../bloc/theme_bloc/theme_bloc.dart';
import '../core/constants/app_constants.dart';
import '../injection_container.dart';
import 'custom_text.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color? bgColor;
  final Color? borderColor;
  final Color? textColor;
  final Function() onPress;

  /// Outlined / transparent fill with primary border and text (e.g. secondary CTA).
  final bool outlined;

  /// Elevation for filled button; outlined ignores this.
  final double elevation;

  const CustomButton({
    super.key,
    required this.text,
    this.bgColor,
    this.borderColor,
    this.textColor,
    required this.onPress,
    this.outlined = false,
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final theme = themeBloc.state.baseTheme;
    final primary = theme.primary;
    final radius = BorderRadius.circular(AppConstants.radius16Px);

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton(
          onPressed: onPress,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? primary,
            side: BorderSide(
              color: borderColor ?? primary,
              width: 2,
            ),
            shape: RoundedRectangleBorder(borderRadius: radius),
            backgroundColor: Colors.transparent,
            splashFactory: InkRipple.splashFactory,
          ),
          child: CustomText(
            text: text,
            weight: FontWeight.w700,
            textColor: textColor ?? primary,
            size: AppConstants.font18Px,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor ?? primary,
          foregroundColor: textColor ?? theme.white,
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(
            color: borderColor ?? primary,
            width: 2,
          ),
          elevation: elevation,
          shadowColor: primary.withValues(alpha: 0.35),
          splashFactory: InkRipple.splashFactory,
        ),
        child: CustomText(
          text: text,
          weight: FontWeight.w700,
          textColor: textColor ?? theme.white,
          size: AppConstants.font18Px,
        ),
      ),
    );
  }
}
