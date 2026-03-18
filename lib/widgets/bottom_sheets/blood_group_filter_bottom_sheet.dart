import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/view_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';
import '../custom_button.dart';
import '../custom_text.dart';

class BloodGroupFilterBottomSheet extends StatefulWidget {
  final String? selectedBloodGroup;

  const BloodGroupFilterBottomSheet({
    super.key,
    this.selectedBloodGroup,
  });

  static Future<String?> show({
    required BuildContext context,
    String? selectedBloodGroup,
  }) async {
    String? result;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BloodGroupFilterBottomSheet(
          selectedBloodGroup: selectedBloodGroup,
        );
      },
    ).then((value) {
      result = value as String?;
    });
    return result;
  }

  @override
  State<BloodGroupFilterBottomSheet> createState() =>
      _BloodGroupFilterBottomSheetState();
}

class _BloodGroupFilterBottomSheetState
    extends State<BloodGroupFilterBottomSheet> {
  late String? _selectedBloodGroup;

  @override
  void initState() {
    super.initState();
    _selectedBloodGroup = widget.selectedBloodGroup;
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;

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
                  text: ViewConstants.filterByBloodGroup,
                  size: AppConstants.font20Px,
                  weight: FontWeight.w700,
                  textColor: baseTheme.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.gap20Px),
          // Blood Group Selection
          Wrap(
            spacing: AppConstants.gap12Px,
            runSpacing: AppConstants.gap12Px,
            children: bloodGroups.map((bloodGroup) {
              final isSelected = _selectedBloodGroup == bloodGroup;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedBloodGroup = bloodGroup;
                  });
                },
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
          ),
          SizedBox(height: AppConstants.gap24Px),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: AppConstants.gap16Px),
                    side: BorderSide(
                      color: baseTheme.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius16Px),
                    ),
                  ),
                  child: CustomText(
                    text: ViewConstants.cancel,
                    size: AppConstants.font16Px,
                    weight: FontWeight.w700,
                    textColor: baseTheme.primary,
                  ),
                ),
              ),
              SizedBox(width: AppConstants.gap16Px),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selectedBloodGroup);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: baseTheme.primary,
                    padding: EdgeInsets.symmetric(vertical: AppConstants.gap16Px),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius16Px),
                    ),
                  ),
                  child: CustomText(
                    text: ViewConstants.done,
                    size: AppConstants.font16Px,
                    weight: FontWeight.w700,
                    textColor: baseTheme.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.gap8Px),
        ],
      ),
    );
  }
}
