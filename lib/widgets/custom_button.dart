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

  const CustomButton({super.key, required this.text,
    this.bgColor, this.borderColor, this.textColor, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor?? themeBloc.state.baseTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius16Px),
          ),
          side: BorderSide(
            color: borderColor??themeBloc.state.baseTheme.primary,
            width: 2,
          ),
          elevation: 2,
        ),
        child: CustomText(
          text: text,
          weight: FontWeight.w700,
          textColor: textColor?? themeBloc.state.baseTheme.white,
          size: AppConstants.font18Px,
        ),
      ),
    );
  }
}
