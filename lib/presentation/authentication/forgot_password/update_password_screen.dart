import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:training_projects/core/extensions/color.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../config/named_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../injection_container.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late ThemeBloc themeBloc;
  late AuthenticationBloc authenticationBloc;

  bool _buttonDisable = true;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    _newPasswordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isValid = _validateForm();
    if (_buttonDisable != !isValid) {
      if (mounted) {
        setState(() {
          _buttonDisable = !isValid;
        });
      }
    }
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_updateButtonState);
    _confirmPasswordController.removeListener(_updateButtonState);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    return newPassword.isNotEmpty && 
           newPassword.length >= 6 && 
           newPassword == confirmPassword;
  }

  Future<void> _handleUpdatePassword() async {
    authenticationBloc.add(
      UpdatePasswordFromRecoveryEvent(
        newPassword: _newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is UpdatePasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully. Please sign in.'),
              backgroundColor: Colors.green,
            ),
          );
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.signIn);
        } else if (state is AuthenticationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        bloc: authenticationBloc,
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: state is AuthenticationLoading,
            overlayColor: baseTheme.background,
            opacity: AppConstants.opacity20Px,
            child: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppConstants.gap20Px),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppConstants.gap20Px,
                    children: [
                      Column(
                        spacing: AppConstants.gap8Px,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: 'Update Password',
                            weight: FontWeight.w800,
                            textColor: baseTheme.primary,
                            size: AppConstants.font28Px,
                          ),
                          CustomText(
                            text: 'Please enter your new password.',
                            weight: FontWeight.w400,
                            size: AppConstants.font14Px,
                            textColor: baseTheme.textColor.fixedOpacity(0.7),
                          ),
                        ],
                      ),
                      CustomTextField(
                        labelText: 'New Password',
                        hintText: 'Enter new password',
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: baseTheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: baseTheme.textColor.fixedOpacity(0.5),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      CustomTextField(
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter new password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: baseTheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: baseTheme.textColor.fixedOpacity(0.5),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: AppConstants.gap20Px),
                      CustomButton(
                        text: 'Update Password',
                        onPress: _buttonDisable ? () {} : _handleUpdatePassword,
                        bgColor: _buttonDisable
                            ? baseTheme.disable
                            : baseTheme.primary,
                        borderColor: _buttonDisable
                            ? baseTheme.disable
                            : baseTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
