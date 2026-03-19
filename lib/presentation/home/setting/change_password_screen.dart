import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_blood/core/extensions/color.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../injection_container.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  bool _isFormValid = false;

  late ThemeBloc _themeBloc;
  late AuthenticationBloc _authenticationBloc;

  static const int _minPasswordLength = 8;

  @override
  void initState() {
    super.initState();
    _themeBloc = sl<ThemeBloc>();
    _authenticationBloc = sl<AuthenticationBloc>();
    _currentPasswordController.addListener(_onFieldChanged);
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_onFieldChanged);
    _newPasswordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {
      _validateInline();
      _isFormValid = _checkAllValid();
    });
  }

  void _validateInline() {
    final currentPw = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (_currentPasswordError != null || currentPw.isNotEmpty) {
      _currentPasswordError =
          currentPw.isEmpty ? ViewConstants.currentPasswordRequired.tr() : null;
    }

    if (_newPasswordError != null || newPw.isNotEmpty) {
      if (newPw.isEmpty) {
        _newPasswordError = ViewConstants.passwordRequired.tr();
      } else if (newPw.length < _minPasswordLength) {
        _newPasswordError = ViewConstants.newPasswordTooShort.tr();
      } else if (currentPw.isNotEmpty && newPw == currentPw) {
        _newPasswordError = ViewConstants.newPasswordSameAsCurrent.tr();
      } else {
        _newPasswordError = null;
      }
    }

    if (_confirmPasswordError != null || confirmPw.isNotEmpty) {
      if (confirmPw.isEmpty) {
        _confirmPasswordError = ViewConstants.confirmPasswordRequired.tr();
      } else if (newPw.isNotEmpty && confirmPw != newPw) {
        _confirmPasswordError = ViewConstants.passwordsDoNotMatch.tr();
      } else {
        _confirmPasswordError = null;
      }
    }
  }

  bool _checkAllValid() {
    final currentPw = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (currentPw.isEmpty) return false;
    if (newPw.isEmpty || newPw.length < _minPasswordLength) return false;
    if (newPw == currentPw) return false;
    if (confirmPw != newPw) return false;
    return true;
  }

  void _validateAllAndShowErrors() {
    final currentPw = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    setState(() {
      _currentPasswordError =
          currentPw.isEmpty ? ViewConstants.currentPasswordRequired.tr() : null;

      if (newPw.isEmpty) {
        _newPasswordError = ViewConstants.passwordRequired.tr();
      } else if (newPw.length < _minPasswordLength) {
        _newPasswordError = ViewConstants.newPasswordTooShort.tr();
      } else if (newPw == currentPw) {
        _newPasswordError = ViewConstants.newPasswordSameAsCurrent.tr();
      } else {
        _newPasswordError = null;
      }

      if (confirmPw.isEmpty) {
        _confirmPasswordError = ViewConstants.confirmPasswordRequired.tr();
      } else if (confirmPw != newPw) {
        _confirmPasswordError = ViewConstants.passwordsDoNotMatch.tr();
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  void _handleChangePassword() {
    _validateAllAndShowErrors();
    if (!_checkAllValid()) return;

    _authenticationBloc.add(
      ChangePasswordEvent(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = _themeBloc.state.baseTheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: _authenticationBloc,
      listener: (context, state) {
        if (state is PasswordChangeSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(ViewConstants.passwordChangedSuccess.tr()),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radius12Px),
              ),
            ),
          );
          AppRouter.pop(context);
        } else if (state is AuthenticationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radius12Px),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        bloc: _authenticationBloc,
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
                    children: [
                      _BackButton(baseTheme: baseTheme),
                      SizedBox(height: AppConstants.gap20Px),
                      _ScreenHeader(baseTheme: baseTheme),
                      SizedBox(height: AppConstants.gap24Px),
                      _SecurityBanner(baseTheme: baseTheme),
                      SizedBox(height: AppConstants.gap30Px),
                      _PasswordField(
                        controller: _currentPasswordController,
                        labelText: ViewConstants.currentPassword,
                        hintText: ViewConstants.currentPasswordHint,
                        obscureText: _obscureCurrentPassword,
                        errorText: _currentPasswordError,
                        baseTheme: baseTheme,
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: _currentPasswordError != null
                              ? Colors.red
                              : baseTheme.primary,
                        ),
                        onToggleVisibility: () => setState(
                          () => _obscureCurrentPassword =
                              !_obscureCurrentPassword,
                        ),
                      ),
                      SizedBox(height: AppConstants.gap20Px),
                      _PasswordField(
                        controller: _newPasswordController,
                        labelText: ViewConstants.newPassword,
                        hintText: ViewConstants.newPasswordHint,
                        obscureText: _obscureNewPassword,
                        errorText: _newPasswordError,
                        baseTheme: baseTheme,
                        prefixIcon: Icon(
                          Icons.key_outlined,
                          color: _newPasswordError != null
                              ? Colors.red
                              : baseTheme.primary,
                        ),
                        onToggleVisibility: () => setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        ),
                      ),
                      if (_newPasswordController.text.isNotEmpty &&
                          _newPasswordError == null)
                        _PasswordStrengthIndicator(
                          password: _newPasswordController.text,
                          baseTheme: baseTheme,
                        ),
                      SizedBox(height: AppConstants.gap20Px),
                      _PasswordField(
                        controller: _confirmPasswordController,
                        labelText: ViewConstants.confirmNewPassword,
                        hintText: ViewConstants.confirmNewPasswordHint,
                        obscureText: _obscureConfirmPassword,
                        errorText: _confirmPasswordError,
                        baseTheme: baseTheme,
                        prefixIcon: Icon(
                          Icons.lock_reset_outlined,
                          color: _confirmPasswordError != null
                              ? Colors.red
                              : baseTheme.primary,
                        ),
                        onToggleVisibility: () => setState(
                          () =>
                              _obscureConfirmPassword = !_obscureConfirmPassword,
                        ),
                      ),
                      SizedBox(height: AppConstants.gap40Px),
                      CustomButton(
                        text: ViewConstants.changePassword,
                        onPress: _handleChangePassword,
                        bgColor:
                            _isFormValid ? baseTheme.primary : baseTheme.disable,
                        borderColor:
                            _isFormValid ? baseTheme.primary : baseTheme.disable,
                      ),
                      SizedBox(height: AppConstants.gap20Px),
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

// ─── Private sub-widgets ────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final BaseTheme baseTheme;

  const _BackButton({required this.baseTheme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => AppRouter.pop(context),
      borderRadius: BorderRadius.circular(AppConstants.radius8Px),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          Icons.arrow_back_ios,
          size: 25,
          color: baseTheme.textColor,
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  final BaseTheme baseTheme;

  const _ScreenHeader({required this.baseTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: baseTheme.primary.fixedOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radius12Px),
              ),
              child: Icon(
                Icons.lock_person_outlined,
                color: baseTheme.primary,
                size: 28,
              ),
            ),
            SizedBox(width: AppConstants.gap14Px),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: ViewConstants.changePasswordTitle,
                    weight: FontWeight.w800,
                    textColor: baseTheme.primary,
                    size: AppConstants.font28Px,
                  ),
                  SizedBox(height: AppConstants.gap4Px),
                  CustomText(
                    text: ViewConstants.changePasswordSubtitle,
                    weight: FontWeight.w400,
                    size: AppConstants.font14Px,
                    textColor: baseTheme.textColor.fixedOpacity(0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecurityBanner extends StatelessWidget {
  final BaseTheme baseTheme;

  const _SecurityBanner({required this.baseTheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.gap16Px,
        vertical: AppConstants.gap14Px,
      ),
      decoration: BoxDecoration(
        color: baseTheme.yellow.fixedOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
        border: Border.all(
          color: baseTheme.yellow.fixedOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.shield_outlined,
              color: baseTheme.yellow,
              size: 18,
            ),
          ),
          SizedBox(width: AppConstants.gap10Px),
          Expanded(
            child: CustomText(
              text:
                  'Use at least 8 characters with a mix of letters and numbers for a strong password.',
              size: AppConstants.font13Px,
              weight: FontWeight.w500,
              textColor: baseTheme.yellow,
              translate: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool obscureText;
  final String? errorText;
  final BaseTheme baseTheme;
  final Widget prefixIcon;
  final VoidCallback onToggleVisibility;

  const _PasswordField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.obscureText,
    this.errorText,
    required this.baseTheme,
    required this.prefixIcon,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          labelText: labelText,
          hintText: hintText,
          controller: controller,
          obscureText: obscureText,
          keyboardType: TextInputType.visiblePassword,
          borderColor: hasError
              ? Colors.red
              : baseTheme.primary.fixedOpacity(0.3),
          prefixIcon: prefixIcon,
          suffixIcon: GestureDetector(
            onTap: onToggleVisibility,
            child: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: hasError
                  ? Colors.red.withValues(alpha: 0.7)
                  : baseTheme.textColor.fixedOpacity(0.45),
              size: 22,
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: AppConstants.gap6Px),
          Padding(
            padding: EdgeInsets.only(left: AppConstants.gap4Px),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: Colors.red,
                ),
                SizedBox(width: AppConstants.gap4Px),
                Expanded(
                  child: CustomText(
                    text: errorText!,
                    size: AppConstants.font12Px,
                    textColor: Colors.red,
                    weight: FontWeight.w500,
                    translate: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final BaseTheme baseTheme;

  const _PasswordStrengthIndicator({
    required this.password,
    required this.baseTheme,
  });

  int get _strengthScore {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=<>?]').hasMatch(password)) score++;
    return score;
  }

  String get _label {
    final s = _strengthScore;
    if (s <= 1) return 'Weak';
    if (s <= 3) return 'Fair';
    if (s == 4) return 'Good';
    return 'Strong';
  }

  Color get _color {
    final s = _strengthScore;
    if (s <= 1) return Colors.red;
    if (s <= 3) return Colors.orange;
    if (s == 4) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final score = _strengthScore;
    final filledSegments = score.clamp(0, 5);

    return Padding(
      padding: EdgeInsets.only(top: AppConstants.gap8Px),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              final isActive = index < filledSegments;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < 4 ? AppConstants.gap4Px : 0,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _color
                        : baseTheme.textColor.fixedOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radius4Px),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: AppConstants.gap4Px),
          Row(
            children: [
              CustomText(
                text: 'Password strength: ',
                size: AppConstants.font12Px,
                textColor: baseTheme.textColor.fixedOpacity(0.5),
                weight: FontWeight.w400,
                translate: false,
              ),
              CustomText(
                text: _label,
                size: AppConstants.font12Px,
                textColor: _color,
                weight: FontWeight.w700,
                translate: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
