import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_blood/core/extensions/color.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../config/named_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../injection_container.dart';
import '../../../mixin/validation_mixin.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with ValidationMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _rememberMe = false;
  
  late ThemeBloc themeBloc;
  late AuthenticationBloc authenticationBloc;
  late SessionManager sessionManager;

  bool signInButtonDisable = true;
  late StateSetter signInButtonStateSetter;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    sessionManager = sl<SessionManager>();
    _addTextControllersListeners();
  }

  void _addTextControllersListeners() {
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isValid = _validateForm();
    if (signInButtonDisable != !isValid) {
      signInButtonDisable = !isValid;
      signInButtonStateSetter(() {});
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is AuthenticationAuthenticated) {
          
          final user = state.userModel ?? sessionManager.getUser();
          if (user != null && user.isOnboardingCompleted) {
            AppRouter.pushNamedAndRemoveUntil(context, RouteNames.bottomNavbar);
          } else {
            AppRouter.pushNamedAndRemoveUntil(context, RouteNames.onboarding);
          }
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
                child: Icon(Icons.arrow_back_ios, size: 25),
              ),
              Column(
                spacing: AppConstants.gap8Px,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: ViewConstants.welcomeBack,
                    weight: FontWeight.w800,
                    textColor: baseTheme.primary,
                    size: AppConstants.font28Px,
                  ),
                  CustomText(
                    text: ViewConstants.signInSubtitle,
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
              StatefulBuilder(
                builder: (context, state) {
                  return CustomTextField(
                    labelText: ViewConstants.password,
                    hintText: ViewConstants.passwordHint,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: baseTheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: baseTheme.textColor.fixedOpacity(0.5),
                      ),
                      onPressed: () {
                        state(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  );
                }
              ),
              Align(
                alignment: AlignmentGeometry.centerRight,
                child: GestureDetector(
                  onTap: () {
                    AppRouter.pushNamed(context, RouteNames.forgotPassword);
                  },
                  child: CustomText(
                    text: ViewConstants.forgotPassword,
                    size: AppConstants.font14Px,
                    weight: FontWeight.w600,
                    textColor: baseTheme.primary,
                    textDecoration: TextDecoration.underline,
                  ),
                ),
              ),
              StatefulBuilder(
                builder: (context, state) {
                  signInButtonStateSetter = state;
                  return CustomButton(
                    text: ViewConstants.signIn,
                    onPress: signInButtonDisable ? () {} : _handleSignIn,
                    bgColor: signInButtonDisable
                        ? baseTheme.disable
                        : baseTheme.primary,
                    borderColor: signInButtonDisable
                        ? baseTheme.disable
                        : baseTheme.primary,
                  );
                }
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: ViewConstants.dontHaveAccount,
                    size: AppConstants.font14Px,
                    weight: FontWeight.w400,
                  ),
                  SizedBox(width: AppConstants.gap4Px),
                  GestureDetector(
                    onTap: () {
                      AppRouter.pushNamed(context, RouteNames.signup);
                    },
                    child: CustomText(
                      text: ViewConstants.signUp,
                      size: AppConstants.font14Px,
                      weight: FontWeight.w700,
                      textColor: baseTheme.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                  ),
                ],
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

  bool _validateForm() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !validateEmail(email)) {
      return false;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _handleSignIn() async {
    authenticationBloc.add(
      SignInEvent(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }
}
