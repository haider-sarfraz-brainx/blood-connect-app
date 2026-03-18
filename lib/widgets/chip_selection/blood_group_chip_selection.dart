import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';
import '../custom_text.dart';

class BloodGroupChipSelection extends StatelessWidget {
  final String? selectedBloodGroup;
  final Function(String) onBloodGroupSelected;

  const BloodGroupChipSelection({
    super.key,
    this.selectedBloodGroup,
    required this.onBloodGroupSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;

    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    return Wrap(
      spacing: AppConstants.gap12Px,
      runSpacing: AppConstants.gap12Px,
      children: bloodGroups.map((bloodGroup) {
        final isSelected = selectedBloodGroup == bloodGroup;

        return GestureDetector(
          onTap: () => onBloodGroupSelected(bloodGroup),
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
                  Icons.bloodtype,
                  color: isSelected
                      ? baseTheme.white
                      : baseTheme.primary,
                  size: 20,
                ),
                SizedBox(width: AppConstants.gap8Px),
                CustomText(
                  text: bloodGroup,
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
