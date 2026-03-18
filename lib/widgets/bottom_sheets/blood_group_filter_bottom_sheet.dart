import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/view_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';
import '../chip_selection/blood_group_chip_selection.dart';
import '../custom_text.dart';

class BloodGroupFilterBottomSheet extends StatefulWidget {
  final String? selectedBloodGroup;

  const BloodGroupFilterBottomSheet({super.key, this.selectedBloodGroup});

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

  void _onBloodGroupSelected(String bloodGroup) {
    setState(() {
      _selectedBloodGroup = bloodGroup;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;

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
          
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: AppConstants.gap20Px),
            decoration: BoxDecoration(
              color: baseTheme.textColor.fixedOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              text: ViewConstants.filterByBloodGroup,
              size: AppConstants.font20Px,
              weight: FontWeight.w700,
              textColor: baseTheme.textColor,
            ),
          ),
          SizedBox(height: AppConstants.gap20Px),
          
          BloodGroupChipSelection(
            selectedBloodGroup: _selectedBloodGroup,
            onBloodGroupSelected: _onBloodGroupSelected,
          ),
          SizedBox(height: AppConstants.gap20Px),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: baseTheme.textColor.fixedOpacity(0.45),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.gap16Px,
                    vertical: AppConstants.gap12Px,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                  ),
                ),
                child: CustomText(
                  text:  ViewConstants.cancel,
                  fontFamily: AppConstants.fontFamilyLato,
                  size: AppConstants.font16Px,
                  weight: FontWeight.w700,
                  textColor: themeBloc.state.baseTheme.disable,
                ),
              ),
              SizedBox(width: AppConstants.gap4Px),
              TextButton(
                onPressed: () => Navigator.pop(context, _selectedBloodGroup),
                style: TextButton.styleFrom(
                  foregroundColor: baseTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.gap16Px,
                    vertical: AppConstants.gap12Px,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                  ),
                ),
                child: CustomText(
                 text:  ViewConstants.done,
                    fontFamily: AppConstants.fontFamilyLato,
                    size: AppConstants.font16Px,
                    weight: FontWeight.w700,
                  textColor: themeBloc.state.baseTheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.gap4Px),
        ],
      ),
    );
  }
}