import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quick_blood/core/extensions/color.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../injection_container.dart';
import '../../../mixin/validation_mixin.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_overlay.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with ValidationMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  late ThemeBloc themeBloc;
  late AuthenticationBloc authenticationBloc;
  late SessionManager sessionManager;

  bool updateButtonDisable = true;
  late StateSetter updateButtonStateSetter;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    sessionManager = sl<SessionManager>();
    _loadUserData();
    _addTextControllersListeners();
  }

  void _loadUserData() {
    final user = sessionManager.getUser();
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
    }
  }

  void _addTextControllersListeners() {
    _nameController.addListener(_updateButtonState);
    _phoneController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    final isValid = _validateForm();
    if (updateButtonDisable != !isValid) {
      updateButtonDisable = !isValid;
      updateButtonStateSetter(() {});
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _phoneController.removeListener(_updateButtonState);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is AuthenticationAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ViewConstants.profileUpdated.tr()),
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
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 25,
                          color: baseTheme.textColor,
                        ),
                      ),
                      Column(
                        spacing: AppConstants.gap8Px,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            text: ViewConstants.editProfileTitle,
                            weight: FontWeight.w800,
                            textColor: baseTheme.primary,
                            size: AppConstants.font28Px,
                          ),
                          CustomText(
                            text: ViewConstants.editProfileSubtitle,
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
                        enabled: false,
                        fillColor: baseTheme.textColor.fixedOpacity(0.05),
                        borderColor: baseTheme.textColor.fixedOpacity(0.2),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: baseTheme.textColor.fixedOpacity(0.5),
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
                        builder: (context, state) {
                          updateButtonStateSetter = state;
                          return CustomButton(
                            text: ViewConstants.updateProfile,
                            onPress: updateButtonDisable ? () {} : _handleUpdateProfile,
                            bgColor: updateButtonDisable
                                ? baseTheme.disable
                                : baseTheme.primary,
                            borderColor: updateButtonDisable
                                ? baseTheme.disable
                                : baseTheme.primary,
                          );
                        },
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

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      return false;
    }

    final user = sessionManager.getUser();
    if (user != null) {
      
      if (name == user.name && phone == user.phone) {
        return false; 
      }
    }

    return true;
  }

  Future<void> _handleUpdateProfile() async {
    authenticationBloc.add(
      UpdateProfileEvent(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      ),
    );
  }
}
