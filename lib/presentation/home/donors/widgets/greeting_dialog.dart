import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../../config/theme/base.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/view_constants.dart';
import '../../../../core/extensions/color.dart';
import '../../../../injection_container.dart';
import '../../../../widgets/custom_text_field.dart';

class GreetingDialog extends StatefulWidget {
  final String recipientName;
  final Function(String message) onSend;

  const GreetingDialog({
    super.key,
    required this.recipientName,
    required this.onSend,
  });

  @override
  State<GreetingDialog> createState() => _GreetingDialogState();
}

class _GreetingDialogState extends State<GreetingDialog> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: baseTheme.background,
          borderRadius: BorderRadius.circular(AppConstants.radius20Px),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: baseTheme.primary.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: baseTheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Send Request'.tr(),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font18Px,
                    fontWeight: FontWeight.w700,
                    color: baseTheme.textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Send a greeting message to ${widget.recipientName} to start a conversation.'.tr(),
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font14Px,
                fontWeight: FontWeight.w400,
                color: baseTheme.textColor.fixedOpacity(0.55),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              hintText: 'e.g. Hi, I can help you with your blood request...'.tr(),
              controller: _messageController,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius12Px,
                        ),
                      ),
                      side: BorderSide(
                        color: baseTheme.textColor.fixedOpacity(0.18),
                      ),
                    ),
                    child: Text(
                      ViewConstants.cancel.tr(),
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font14Px,
                        fontWeight: FontWeight.w600,
                        color: baseTheme.textColor.fixedOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        widget.onSend(_messageController.text.trim());
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: baseTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius12Px,
                        ),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Send'.tr(),
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font14Px,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
