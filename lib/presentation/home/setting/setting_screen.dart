import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/language_bloc/language_bloc.dart';
import '../../../bloc/language_bloc/language_events.dart';
import '../../../bloc/language_bloc/language_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../bloc/theme_bloc/theme_events.dart';
import '../../../bloc/theme_bloc/theme_states.dart';
import '../../../config/app_router.dart';
import '../../../config/config.dart';
import '../../../config/named_router.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../data/models/user_model.dart';
import '../../../injection_container.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/loading_overlay.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late ThemeBloc themeBloc;
  late LanguageBloc languageBloc;
  late AuthenticationBloc authenticationBloc;
  late SessionManager sessionManager;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    languageBloc = sl<LanguageBloc>();
    authenticationBloc = sl<AuthenticationBloc>();
    sessionManager = sl<SessionManager>();
    languageBloc.add(LoadLanguage());
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;
    final settingsColors = baseTheme.settings;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is AuthenticationUnauthenticated) {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.welcome);
        } else if (state is AuthenticationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is AuthenticationAuthenticated) {
          // Trigger rebuild when user is authenticated to refresh user data
          setState(() {});
        }
      },
      child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        bloc: authenticationBloc,
        builder: (context, authState) {
          // Read user data inside BlocBuilder to get fresh data when state changes
          final user = sessionManager.getUser();
          
          return LoadingOverlay(
            isLoading: authState is AuthenticationLoading,
            overlayColor: baseTheme.background,
            opacity: AppConstants.opacity20Px,
            child: Scaffold(
              backgroundColor: baseTheme.background,
              appBar: AppBar(
                title: CustomText(
                  text: ViewConstants.setting,
                  size: AppConstants.font22Px,
                  weight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                backgroundColor: baseTheme.background,
                elevation: 0,
                centerTitle: false,
                toolbarHeight: 60,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppConstants.gap20Px),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      _buildProfileSection(baseTheme, user),
                      SizedBox(height: AppConstants.gap24Px),

                      // Account Section
                      _buildSectionTitle(baseTheme, ViewConstants.account),
                      SizedBox(height: AppConstants.gap12Px),
                      _buildSettingsCard(
                        baseTheme,
                        settingsColors,
                        children: [
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.person_outline,
                            title: ViewConstants.editProfile,
                            onTap: () {
                              AppRouter.pushNamed(context, RouteNames.editProfile);
                            },
                          ),
                          _buildDivider(baseTheme),
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.bloodtype_outlined,
                            title: ViewConstants.editOnboarding,
                            onTap: () {
                              AppRouter.pushNamed(context, RouteNames.editOnboarding);
                            },
                          ),
                          _buildDivider(baseTheme),
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.lock_outline,
                            title: ViewConstants.changePassword,
                            onTap: () {
                              // TODO: Navigate to change password screen
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.gap24Px),

                      // Preferences Section
                      _buildSectionTitle(baseTheme, ViewConstants.notifications),
                      SizedBox(height: AppConstants.gap12Px),
                      _buildSettingsCard(
                        baseTheme,
                        settingsColors,
                        children: [
                          _buildSwitchTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.notifications_outlined,
                            title: ViewConstants.enableNotifications,
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.gap24Px),

                      // More Section
                      _buildSectionTitle(baseTheme, ViewConstants.about),
                      SizedBox(height: AppConstants.gap12Px),
                      _buildSettingsCard(
                        baseTheme,
                        settingsColors,
                        children: [
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.privacy_tip_outlined,
                            title: ViewConstants.privacyPolicy,
                            onTap: () {
                              // TODO: Open privacy policy
                            },
                          ),
                          _buildDivider(baseTheme),
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.description_outlined,
                            title: ViewConstants.termsOfService,
                            onTap: () {
                              // TODO: Open terms of service
                            },
                          ),
                          _buildDivider(baseTheme),
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.help_outline,
                            title: ViewConstants.help,
                            onTap: () {
                              // TODO: Navigate to help screen
                            },
                          ),
                          _buildDivider(baseTheme),
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.email_outlined,
                            title: ViewConstants.contactUs,
                            onTap: () {
                              // TODO: Open contact us
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: AppConstants.gap40Px),

                      _buildSettingsCard(
                        baseTheme,
                        settingsColors,
                        children: [
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.delete_outline,
                            title: ViewConstants.deleteAccount,
                            onTap: () {
                              // TODO: Open privacy policy
                            },
                          ),
                          _buildDivider(baseTheme),
                          _buildSettingsTile(
                            baseTheme,
                            settingsColors,
                            icon: Icons.exit_to_app,
                            title: ViewConstants.logout,
                            onTap:_showLogoutDialog,
                          ),
                        ],
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

  Widget _buildProfileSection(BaseTheme baseTheme, UserModel? user) {
    final initials = (user?.name != null && user!.name.isNotEmpty)
        ? user.name.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      padding: EdgeInsets.all(AppConstants.gap24Px),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseTheme.primary.fixedOpacity(0.08),
            baseTheme.primary.fixedOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radius20Px),
        border: Border.all(
          color: baseTheme.primary.fixedOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: baseTheme.primary.fixedOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseTheme.primary,
                  baseTheme.primary.fixedOpacity(0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: baseTheme.primary.fixedOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CustomText(
                text: initials,
                size: AppConstants.font28Px,
                weight: FontWeight.w700,
                textColor: baseTheme.white,
                translate: false,
              ),
            ),
          ),
          SizedBox(width: AppConstants.gap20Px),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: user?.name ?? 'User',
                  size: AppConstants.font20Px,
                  weight: FontWeight.w700,
                  translate: false,
                ),
                SizedBox(height: AppConstants.gap6Px),
                CustomText(
                  text: user?.email ?? '',
                  size: AppConstants.font14Px,
                  textColor: baseTheme.textColor.fixedOpacity(0.65),
                  translate: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BaseTheme baseTheme, String title) {
    return Padding(
      padding: EdgeInsets.only(left: AppConstants.gap4Px),
      child: CustomText(
        text: title,
        size: AppConstants.font17Px,
        weight: FontWeight.w700,
        textColor: baseTheme.textColor.fixedOpacity(0.85),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildSettingsCard(
    BaseTheme baseTheme,
    SettingsColors settingsColors, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius20Px),
        border: Border.all(
          color: baseTheme.textColor.fixedOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: baseTheme.textColor.fixedOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: baseTheme.textColor.fixedOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
    BaseTheme baseTheme,
    SettingsColors settingsColors, {
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        splashColor: baseTheme.primary.fixedOpacity(0.1),
        highlightColor: baseTheme.primary.fixedOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.all(AppConstants.gap16Px,),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: settingsColors.iconBackground,
                  borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                  boxShadow: [
                    BoxShadow(
                      color: baseTheme.primary.fixedOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: settingsColors.icon,
                  size: 22,
                ),
              ),
              SizedBox(width: AppConstants.gap16Px),
              Expanded(
                child: CustomText(
                  text: title,
                  size: AppConstants.font16Px,
                  weight: FontWeight.w600,
                  textColor: settingsColors.tileTitle,
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: AppConstants.gap8Px),
                trailing,
              ],
              if (showArrow && trailing == null)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: baseTheme.textColor.fixedOpacity(0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BaseTheme baseTheme,
    SettingsColors settingsColors, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.gap16Px,
        vertical: AppConstants.gap18Px,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: settingsColors.iconBackground,
              borderRadius: BorderRadius.circular(AppConstants.radius12Px),
              boxShadow: [
                BoxShadow(
                  color: baseTheme.primary.fixedOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: settingsColors.icon,
              size: 22,
            ),
          ),
          SizedBox(width: AppConstants.gap16Px),
          Expanded(
            child: CustomText(
              text: title,
              size: AppConstants.font16Px,
              weight: FontWeight.w600,
              textColor: settingsColors.tileTitle,
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: baseTheme.primary,
              thumbColor: MaterialStateProperty.all(settingsColors.switchThumb),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BaseTheme baseTheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.gap16Px),
      child: Divider(
        height: 1,
        thickness: 1,
        color: baseTheme.textColor.fixedOpacity(0.08),
        indent: 60,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeBloc.state.baseTheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius16Px),
          ),
          title: CustomText(
            text: ViewConstants.logout,
            weight: FontWeight.w700,
            size: AppConstants.font20Px,
          ),
          content: CustomText(
            text: 'Are you sure you want to logout?',
            size: AppConstants.font16Px,
            translate: false,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomText(
                text: 'Cancel',
                textColor: themeBloc.state.baseTheme.textColor,
                translate: false,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                authenticationBloc.add(const SignOutEvent());
              },
              child: CustomText(
                text: ViewConstants.logout,
                textColor: themeBloc.state.baseTheme.primary,
                weight: FontWeight.w700,
              ),
            ),
          ],
        );
      },
    );
  }
}
