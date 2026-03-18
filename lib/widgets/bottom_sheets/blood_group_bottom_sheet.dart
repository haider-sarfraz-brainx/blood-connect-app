import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';
import '../custom_text.dart';

class BloodGroupBottomSheet extends StatelessWidget {
  final String? selectedBloodGroup;
  final Function(String) onBloodGroupSelected;

  const BloodGroupBottomSheet({
    super.key,
    this.selectedBloodGroup,
    required this.onBloodGroupSelected,
  });

  static Future<String?> show({
    required BuildContext context,
    String? selectedBloodGroup,
  }) async {
    String? result;
    await showModalBottomSheet(
      context: context,
      backgroundColor: sl<ThemeBloc>().state.baseTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radius20Px)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return BloodGroupBottomSheet(
          selectedBloodGroup: selectedBloodGroup,
          onBloodGroupSelected: (bloodGroup) {
            result = bloodGroup;
            Navigator.pop(context);
          },
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;
    final settingsColors = baseTheme.settings;

    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.gap20Px,
        right: AppConstants.gap20Px,
        top: AppConstants.gap20Px,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppConstants.gap20Px,
      ),
      decoration: BoxDecoration(
        color: baseTheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius20Px),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: AppConstants.gap20Px),
            decoration: BoxDecoration(
              color: baseTheme.textColor.fixedOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Row(
            children: [
              Expanded(
                child: CustomText(
                  text: 'Select Blood Group',
                  size: AppConstants.font20Px,
                  weight: FontWeight.w700,
                  textColor: baseTheme.textColor,
                  translate: false,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: baseTheme.textColor.fixedOpacity(0.6),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: AppConstants.gap20Px),
          // Blood Group List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: bloodGroups.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: baseTheme.textColor.fixedOpacity(0.08),
              ),
              itemBuilder: (context, index) {
                final bloodGroup = bloodGroups[index];
                final isSelected = selectedBloodGroup == bloodGroup;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onBloodGroupSelected(bloodGroup),
                    borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppConstants.gap16Px,
                        vertical: AppConstants.gap18Px,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? baseTheme.primary.fixedOpacity(0.1)
                                  : settingsColors.iconBackground,
                              borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                              border: Border.all(
                                color: isSelected
                                    ? baseTheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: CustomText(
                                text: bloodGroup,
                                size: AppConstants.font18Px,
                                weight: FontWeight.w700,
                                textColor: isSelected
                                    ? baseTheme.primary
                                    : baseTheme.textColor,
                                translate: false,
                              ),
                            ),
                          ),
                          SizedBox(width: AppConstants.gap16Px),
                          Expanded(
                            child: CustomText(
                              text: bloodGroup,
                              size: AppConstants.font16Px,
                              weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              textColor: isSelected
                                  ? baseTheme.primary
                                  : baseTheme.textColor,
                              translate: false,
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: baseTheme.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: AppConstants.gap20Px),
        ],
      ),
    );
  }
}
