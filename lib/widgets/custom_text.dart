import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../bloc/theme_bloc/theme_bloc.dart';
import '../core/constants/app_constants.dart';
import '../injection_container.dart';


class CustomText extends StatelessWidget {
  final String text;
  final double? size;
  final double? height;
  final double letterSpacing;
  final bool translate;
  final String fontFamily;
  final Color? textColor;
  final TextOverflow? overflow;
  final TextAlign? align;
  final int? maxLines;
  final TextDecoration? textDecoration;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    return Text(
      translate? text.tr(): text,
      textAlign: align,
      maxLines: maxLines,
      style: TextStyle(
          color: textColor?? themeBloc.state.baseTheme.textColor,
          fontFamily: fontFamily,
          fontSize: size??AppConstants.font16Px,
          height: height,
          letterSpacing: letterSpacing,
          fontWeight: weight,
          decoration: textDecoration,
          overflow: overflow,
          decorationColor: textColor??themeBloc.state.baseTheme.textColor,
          decorationThickness: 1,
          decorationStyle: TextDecorationStyle.solid),
    );
  }

  const CustomText({
    super.key,
    required this.text,
    this.size,
    this.fontFamily = AppConstants.fontFamilyLato,
    this.textColor,
    this.translate = true,
    this.overflow,
    this.height,
    this.letterSpacing = 0.0,
    this.maxLines,
    this.align,
    this.textDecoration,
    this.weight = FontWeight.w400,
  });
}
