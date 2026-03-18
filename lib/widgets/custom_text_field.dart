import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:training_projects/core/extensions/color.dart';
import '../bloc/theme_bloc/theme_bloc.dart';
import '../core/constants/app_constants.dart';
import '../injection_container.dart';
import 'custom_text.dart';

class CustomTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderRadius;
  final bool translate;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
    this.fillColor,
    this.borderColor,
    this.borderRadius,
    this.translate = true,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          CustomText(
            text: labelText!,
            size: AppConstants.font14Px,
            weight: FontWeight.w600,
            textColor: baseTheme.textColor,
            translate: translate,
          ),
          SizedBox(height: AppConstants.gap8Px),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          onChanged: onChanged,
          focusNode: focusNode,
          onTapOutside: (focus)=> FocusScope.of(context).unfocus(),
          style: TextStyle(
            color: baseTheme.textColor,
            fontSize: AppConstants.font16Px,
            fontFamily: AppConstants.fontFamilyLato,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hintText != null ? (translate ? hintText!.tr() : hintText!) : null,
            hintStyle: TextStyle(
              color: baseTheme.textColor.fixedOpacity(0.5),
              fontSize: AppConstants.font16Px,
              fontFamily: AppConstants.fontFamilyLato,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? baseTheme.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppConstants.gap16Px,
              vertical: AppConstants.gap16Px,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radius12Px,
              ),
              borderSide: BorderSide(
                color: borderColor ?? baseTheme.primary.fixedOpacity(0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radius12Px,
              ),
              borderSide: BorderSide(
                color: borderColor ?? baseTheme.primary.fixedOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radius12Px,
              ),
              borderSide: BorderSide(
                color: baseTheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radius12Px,
              ),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radius12Px,
              ),
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radius12Px,
              ),
              borderSide: BorderSide(
                color: baseTheme.textColor.fixedOpacity(0.2),
                width: 1,
              ),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}
