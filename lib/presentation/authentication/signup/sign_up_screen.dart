import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:training_projects/core/extensions/color.dart';
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with ValidationMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  
  late ThemeBloc themeBloc;
  late AuthenticationBloc authenticationBloc;
  late SessionManager sessionManager;

  bool signUpButtonDisable = true;
  late StateSetter signUpButtonStateSetter;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    sessionManager = sl<SessionManager>();
    _addTextControllersListeners();
  }

  void _addTextControllersListeners() {
    _nameController.addListener(_updateButtonState);
    _emailController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isValid = _validateForm();
    if (signUpButtonDisable != !isValid) {
        signUpButtonDisable = !isValid;
        signUpButtonStateSetter(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _emailController.removeListener(_updateButtonState);
    _phoneController.removeListener(_updateButtonState);
    _passwordController.removeListener(_updateButtonState);
    _confirmPasswordController.removeListener(_updateButtonState);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

          if (state.userModel != null && state.userModel!.isOnboardingCompleted) {
            
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
                  onTap: ()=> AppRouter.pop(context),
                  child: Icon(Icons.arrow_back_ios, size: 25,)),
              Column(
                spacing: AppConstants.gap8Px,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: ViewConstants.createAccount,
                    weight: FontWeight.w800,
                    textColor: baseTheme.primary,
                    size: AppConstants.font28Px,
                  ),

                  CustomText(
                    text: ViewConstants.signUpSubtitle,
                    weight: FontWeight.w400,
                    size: AppConstants.font14Px,
                    textColor: baseTheme.textColor.fixedOpacity(0.7),
                  ),
                ],
              ),
              CustomTextField(
                labelText: ViewConstants.fullName,
                hintText: ViewConstants.fullNameHint,
                controller: _nameController,
                keyboardType: TextInputType.name,
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: baseTheme.primary,
                ),
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

              CustomTextField(
                labelText: ViewConstants.phoneNumber,
                hintText: ViewConstants.phoneNumberHint,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: baseTheme.primary,
                ),
              ),

              StatefulBuilder(
                builder: (context,state) {
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
                        _obscurePassword ? Icons.visibility_outlined : Icons
                            .visibility_off_outlined,
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

              StatefulBuilder(
                builder: (context,state) {
                  return CustomTextField(
                    labelText: ViewConstants.confirmPassword,
                    hintText: ViewConstants.confirmPasswordHint,
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
                        color: baseTheme.textColor.withOpacity(0.5),
                      ),
                      onPressed: () {
                        state(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  );
                }
              ),

              StatefulBuilder(
                builder: (context, state) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          state(() {
                            _acceptTerms = value ?? false;
                          });
                          _updateButtonState();
                        },
                        activeColor: baseTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppConstants.radius4Px),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            state(() {
                              _acceptTerms = !_acceptTerms;
                            });
                            _updateButtonState();
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: AppConstants.gap12Px),
                            child: CustomText(
                              text: ViewConstants.acceptTerms,
                              size: AppConstants.font14Px,
                              weight: FontWeight.w400,
                              maxLines: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              ),

              StatefulBuilder(
                builder: (context,state) {
                  signUpButtonStateSetter= state;
                  return CustomButton(
                    text: ViewConstants.signUp,
                    onPress: signUpButtonDisable ? () {} : _handleSignUp,
                    bgColor: (signUpButtonDisable)? baseTheme.disable:baseTheme.primary,
                    borderColor: (signUpButtonDisable)? baseTheme.disable:baseTheme.primary,
                  );
                }
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: ViewConstants.alreadyHaveAccount,
                    size: AppConstants.font14Px,
                    weight: FontWeight.w400,
                  ),
                  SizedBox(width: AppConstants.gap4Px),
                  GestureDetector(
                    onTap: () {
                      AppRouter.pushNamed(context, RouteNames.signIn);
                    },
                    child: CustomText(
                      text: ViewConstants.signIn,
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
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      return false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !validateEmail(email)) {
      return false;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      return false;
    }

    final password = _passwordController.text;
    if (password.isEmpty || password.length < 8) {
      return false;
    }

    final confirmPassword = _confirmPasswordController.text;
    if (confirmPassword.isEmpty || confirmPassword != password) {
      return false;
    }

    if (!_acceptTerms) {
      return false;
    }

    return true;
  }

  Future<void> _handleSignUp() async {
    authenticationBloc.add(
      SignUpEvent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

}
