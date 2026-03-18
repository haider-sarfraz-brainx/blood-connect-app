import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';
import '../custom_text.dart';

class GenderChipSelection extends StatelessWidget {
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const GenderChipSelection({
    super.key,
    this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;

    final genders = [
      {'value': 'Male', 'icon': Icons.male},
      {'value': 'Female', 'icon': Icons.female},
      {'value': 'Other', 'icon': Icons.person_outline},
    ];

    return Wrap(
      spacing: AppConstants.gap12Px,
      runSpacing: AppConstants.gap12Px,
      children: genders.map((gender) {
        final genderValue = gender['value'] as String;
        final genderIcon = gender['icon'] as IconData;
        final isSelected = selectedGender == genderValue;

        return GestureDetector(
          onTap: () => onGenderSelected(genderValue),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.gap20Px,
              vertical: AppConstants.gap12Px,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? baseTheme.primary
                  : baseTheme.white,
              borderRadius: BorderRadius.circular(AppConstants.radius12Px),
              border: Border.all(
                color: isSelected
                    ? baseTheme.primary
                    : baseTheme.primary.fixedOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  genderIcon,
                  color: isSelected
                      ? baseTheme.white
                      : baseTheme.primary,
                  size: 20,
                ),
                SizedBox(width: AppConstants.gap8Px),
                CustomText(
                  text: genderValue,
                  size: AppConstants.font16Px,
                  weight: FontWeight.w600,
                  textColor: isSelected
                      ? baseTheme.white
                      : baseTheme.primary,
                  translate: false,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
