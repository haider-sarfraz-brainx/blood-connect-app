import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../bloc/theme_bloc/theme_bloc.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/view_constants.dart';
import '../../core/extensions/color.dart';
import '../../injection_container.dart';
import '../custom_text.dart';

class CupertinoDatePickerBottomSheet extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final String title;
  final CupertinoDatePickerMode mode;

  const CupertinoDatePickerBottomSheet({
    super.key,
    this.initialDate,
    this.minimumDate,
    this.maximumDate,
    required this.title,
    this.mode = CupertinoDatePickerMode.date,
  });

  static Future<DateTime?> show({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
    required String title,
    CupertinoDatePickerMode mode = CupertinoDatePickerMode.date,
  }) async {
    DateTime? result;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CupertinoDatePickerBottomSheet(
          initialDate: initialDate,
          minimumDate: minimumDate,
          maximumDate: maximumDate,
          title: title,
          mode: mode,
        );
      },
    ).then((value) {
      result = value as DateTime?;
    });
    return result;
  }

  @override
  State<CupertinoDatePickerBottomSheet> createState() =>
      _CupertinoDatePickerBottomSheetState();
}

class _CupertinoDatePickerBottomSheetState
    extends State<CupertinoDatePickerBottomSheet> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;
    final minDate = widget.minimumDate ?? DateTime(1900);
    final maxDate = widget.maximumDate ?? DateTime.now();

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: baseTheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius20Px),
        ),
      ),
      child: Column(
        children: [
          
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(
              top: AppConstants.gap12Px,
              bottom: AppConstants.gap8Px,
            ),
            decoration: BoxDecoration(
              color: baseTheme.textColor.fixedOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.gap20Px,
              vertical: AppConstants.gap16Px,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: baseTheme.textColor.fixedOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: widget.title,
                    size: AppConstants.font20Px,
                    weight: FontWeight.w700,
                    textColor: baseTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: CupertinoDatePicker(
              initialDateTime: selectedDate,
              minimumDate: minDate,
              maximumDate: maxDate,
              mode: widget.mode,
              use24hFormat: false,
              onDateTimeChanged: (DateTime newDate) {
                setState(() {
                  selectedDate = newDate;
                });
              },
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.gap20Px,
              vertical: AppConstants.gap16Px,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: baseTheme.textColor.fixedOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 80,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: CustomText(
                      text: ViewConstants.cancel,
                      textColor: baseTheme.textColor.fixedOpacity(0.7),
                    ),
                  ),
                ),
                SizedBox(width: AppConstants.gap8Px),
                SizedBox(
                  width: 80,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, selectedDate),
                    child: CustomText(
                      text: ViewConstants.done,
                      textColor: baseTheme.primary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )

        ],
      ),
    );
  }
}
