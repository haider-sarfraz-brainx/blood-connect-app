import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_blood/core/extensions/color.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../injection_container.dart';
import '../../../mixin/validation_mixin.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with ValidationMixin {
  final _emailController = TextEditingController();

  late ThemeBloc themeBloc;
  late AuthenticationBloc authenticationBloc;

  bool _buttonDisable = true;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    _emailController.addListener(_updateButtonState);
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
    _emailController.removeListener(_updateButtonState);
    _emailController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final email = _emailController.text.trim();
    return email.isNotEmpty && validateEmail(email);
  }

  Future<void> _handleForgotPassword() async {
    authenticationBloc.add(
      ForgotPasswordEvent(
        email: _emailController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is ForgotPasswordEmailSent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent to your email.'),
              backgroundColor: Colors.green,
            ),
          );
          AppRouter.pop(context);
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
                      InkWell(
                        onTap: () => AppRouter.pop(context),
                        child: const Icon(Icons.arrow_back_ios, size: 25),
                      ),
                      Column(
                        spacing: AppConstants.gap8Px,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: ViewConstants.forgotPassword,
                            weight: FontWeight.w800,
                            textColor: baseTheme.primary,
                            size: AppConstants.font28Px,
                          ),
                          CustomText(
                            text: 'Enter your email address to receive a password reset link.',
                            weight: FontWeight.w400,
                            size: AppConstants.font14Px,
                            textColor: baseTheme.textColor.fixedOpacity(0.7),
                          ),
                        ],
                      ),
                      CustomTextField(
                        labelText: ViewConstants.email,
                        hintText: ViewConstants.emailHint,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: baseTheme.primary,
                        ),
                      ),
                      CustomButton(
                        text: 'Send Link',
                        onPress: _buttonDisable ? () {} : _handleForgotPassword,
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
