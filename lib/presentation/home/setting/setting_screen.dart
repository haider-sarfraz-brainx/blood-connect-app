import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/web_view_screen.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/language_bloc/language_bloc.dart';
import '../../../bloc/language_bloc/language_events.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../bloc/theme_bloc/theme_states.dart';
import '../../../config/app_router.dart';
import '../../../config/named_router.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../data/models/user_model.dart';
import '../../../injection_container.dart';
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
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is AuthenticationUnauthenticated) {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.welcome);
        } else if (state is AuthenticationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.radius12Px),
              ),
            ),
          );
        } else if (state is AuthenticationAuthenticated) {
          setState(() {});
        }
      },
      child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        bloc: authenticationBloc,
        builder: (context, authState) {
          final user = sessionManager.getUser();

          return BlocBuilder<ThemeBloc, ThemeState>(
            bloc: themeBloc,
            builder: (context, themeState) {
              final baseTheme = themeState.baseTheme;
              final settingsColors = baseTheme.settings;

              return LoadingOverlay(
                isLoading: authState is AuthenticationLoading,
                overlayColor: baseTheme.background,
                opacity: AppConstants.opacity20Px,
                child: Scaffold(
                  backgroundColor: baseTheme.background,
                  appBar: AppBar(
                    backgroundColor: baseTheme.background,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    centerTitle: false,
                    title: Text(
                      ViewConstants.setting.tr(),
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font20Px,
                        fontWeight: FontWeight.w700,
                        color: baseTheme.textColor,
                      ),
                    ),
                  ),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          _ProfileCard(
                            user: user,
                            baseTheme: baseTheme,
                            onEditTap: () => AppRouter.pushNamed(
                              context,
                              RouteNames.editProfile,
                            ),
                          ),

                          const SizedBox(height: 28),

                          _SectionLabel(
                            label: ViewConstants.account,
                            baseTheme: baseTheme,
                          ),
                          const SizedBox(height: 10),
                          _SettingsGroup(
                            baseTheme: baseTheme,
                            children: [
                              _SettingsTile(
                                icon: Icons.person_rounded,
                                title: ViewConstants.editProfile,
                                baseTheme: baseTheme,
                                settingsColors: settingsColors,
                                onTap: () => AppRouter.pushNamed(
                                  context,
                                  RouteNames.editProfile,
                                ),
                              ),
                              _TileDivider(baseTheme: baseTheme),
                              _SettingsTile(
                                icon: Icons.water_drop_rounded,
                                title: ViewConstants.editOnboarding,
                                baseTheme: baseTheme,
                                settingsColors: settingsColors,
                                onTap: () => AppRouter.pushNamed(
                                  context,
                                  RouteNames.editOnboarding,
                                ),
                              ),
                              _TileDivider(baseTheme: baseTheme),
                              _SettingsTile(
                                icon: Icons.lock_rounded,
                                title: ViewConstants.changePassword,
                                baseTheme: baseTheme,
                                settingsColors: settingsColors,
                                onTap: () => AppRouter.pushNamed(
                                context,
                                RouteNames.changePassword,
                              ),
                              ),
                              _SettingsTile(
                                icon: Icons.lock_rounded,
                                title: ViewConstants.blockedUsers,
                                baseTheme: baseTheme,
                                settingsColors: settingsColors,
                                onTap: () => AppRouter.pushNamed(
                                  context,
                                  RouteNames.blockedUsers,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          _SectionLabel(
                            label: ViewConstants.about,
                            baseTheme: baseTheme,
                          ),
                          const SizedBox(height: 10),
                          _SettingsGroup(
                            baseTheme: baseTheme,
                            children: [
                              _SettingsTile(
                                icon: Icons.shield_rounded,
                                title: ViewConstants.privacyPolicy,
                                baseTheme: baseTheme,
                                settingsColors: settingsColors,
                                onTap: () => AppRouter.push(
                                  context,
                                  const WebViewScreen(
                                    url: 'https://www.termsfeed.com/live/b103e918-cbfe-4cb2-8582-d75af9594283',
                                    title: 'Privacy Policy',
                                  ),
                                ),
                              ),
                              _TileDivider(baseTheme: baseTheme),
                              _SettingsTile(
                                icon: Icons.description_rounded,
                                title: ViewConstants.termsOfService,
                                baseTheme: baseTheme,
                                settingsColors: settingsColors,
                                onTap: () => AppRouter.push(
                                  context,
                                  const WebViewScreen(
                                    url: 'https://www.termsfeed.com/live/437a2d49-1dc2-46c5-8d42-69a201873ad2',
                                    title: 'Terms & Conditions',
                                  ),
                                ),
                              ),
                              _TileDivider(baseTheme: baseTheme),
                              _SettingsTile(
                                icon: Icons.help_rounded,
                                title: ViewConstants.help,
                                baseTheme: baseTheme,
                                settingsColors: settingsColors,
                                onTap: _launchHelpEmail,
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          _DangerGroup(
                            children: [
                              _DangerTile(
                                icon: Icons.delete_rounded,
                                title: ViewConstants.deleteAccount,
                                baseTheme: baseTheme,
                                onTap: () => _showDeleteAccountDialog(baseTheme),
                              ),
                              _TileDivider(
                                baseTheme: baseTheme,
                                color: Colors.red.fixedOpacity(0.08),
                              ),
                              _DangerTile(
                                icon: Icons.logout_rounded,
                                title: ViewConstants.logout,
                                baseTheme: baseTheme,
                                onTap: () => _showLogoutDialog(baseTheme),
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
          );
        },
      ),
    );
  }

  Future<void> _launchHelpEmail() async {
    const address = 'haider.sarfraz@brainxtech.com';
    const subject = 'Help & Support - Blood Connect';
    // Build the URI manually so spaces are encoded as %20 (RFC 2368),
    // not as + which Uri(..., queryParameters) produces and Android rejects.
    final uri = Uri.parse(
      'mailto:$address?subject=${Uri.encodeComponent(subject)}',
    );

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Could not open email app. Please email us at $address',
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radius12Px),
            ),
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BaseTheme baseTheme) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
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
                        color: Colors.orange.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      ViewConstants.logout.tr(),
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
                  'Are you sure you want to sign out of your account?',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font14Px,
                    fontWeight: FontWeight.w400,
                    color: baseTheme.textColor.fixedOpacity(0.55),
                    height: 1.5,
                  ),
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
                          Navigator.pop(context);
                          authenticationBloc.add(const SignOutEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
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
                          ViewConstants.logout.tr(),
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
      },
    );
  }

  void _showDeleteAccountDialog(BaseTheme baseTheme) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
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
                        color: Colors.red.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: Colors.red.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      ViewConstants.deleteAccount.tr(),
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
                  'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font14Px,
                    fontWeight: FontWeight.w400,
                    color: baseTheme.textColor.fixedOpacity(0.55),
                    height: 1.5,
                  ),
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
                          Navigator.pop(context);
                          authenticationBloc.add(const DeleteAccountEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
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
                          ViewConstants.delete.tr(),
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
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final UserModel? user;
  final BaseTheme baseTheme;
  final VoidCallback onEditTap;

  const _ProfileCard({
    required this.user,
    required this.baseTheme,
    required this.onEditTap,
  });

  Color _bloodColor(String? bg) {
    if (bg == null) return const Color(0xFFE53935);
    final g = bg.toUpperCase();
    if (g.startsWith('AB')) return const Color(0xFF8E24AA);
    if (g.startsWith('A')) return const Color(0xFFFF6B35);
    if (g.startsWith('B')) return const Color(0xFF2196F3);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final initial = (user?.name != null && user!.name.isNotEmpty)
        ? user!.name[0].toUpperCase()
        : 'U';
    final bloodColor = _bloodColor(user?.bloodGroup);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseTheme.primary.withOpacity(0.10),
            baseTheme.primary.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radius20Px),
        border: Border.all(
          color: baseTheme.primary.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  baseTheme.primary,
                  baseTheme.primary.withOpacity(0.72),
                ],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font24Px,
                fontWeight: FontWeight.w800,
                color: baseTheme.white,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font18Px,
                    fontWeight: FontWeight.w700,
                    color: baseTheme.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font13Px,
                    fontWeight: FontWeight.w400,
                    color: baseTheme.textColor.fixedOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (user?.bloodGroup != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: bloodColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 11,
                          color: bloodColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user!.bloodGroup!,
                          style: TextStyle(
                            fontFamily: AppConstants.fontFamilyLato,
                            fontSize: AppConstants.font12Px,
                            fontWeight: FontWeight.w700,
                            color: bloodColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          GestureDetector(
            onTap: onEditTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: baseTheme.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.edit_rounded,
                size: 16,
                color: baseTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final BaseTheme baseTheme;
  final bool translate;
  final bool isRed;

  const _SectionLabel({
    required this.label,
    required this.baseTheme,
    this.translate = true,
    this.isRed = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = translate ? label.tr() : label;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: AppConstants.fontFamilyLato,
          fontSize: AppConstants.font12Px,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isRed
              ? Colors.red.shade400
              : baseTheme.textColor.fixedOpacity(0.38),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final BaseTheme baseTheme;
  final List<Widget> children;

  const _SettingsGroup({
    required this.baseTheme,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        child: Column(children: children),
      ),
    );
  }
}

class _DangerGroup extends StatelessWidget {
  final List<Widget> children;

  const _DangerGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.025),
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        border: Border.all(
          color: Colors.red.withOpacity(0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final BaseTheme baseTheme;
  final SettingsColors settingsColors;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.baseTheme,
    required this.settingsColors,
    required this.onTap,
    this.trailing,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: baseTheme.primary.withOpacity(0.06),
        highlightColor: baseTheme.primary.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: settingsColors.iconBackground,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radius10Px),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: settingsColors.icon),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title.tr(),
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: AppConstants.font16Px,
                    fontWeight: FontWeight.w500,
                    color: settingsColors.tileTitle,
                  ),
                ),
              ),

              if (trailing != null) ...[
                const SizedBox(width: AppConstants.gap8Px),
                trailing!,
              ] else if (showArrow)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: baseTheme.textColor.fixedOpacity(0.25),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final BaseTheme baseTheme;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.title,
    required this.baseTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const dangerColor = Color(0xFFC62828);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.red.withOpacity(0.06),
        highlightColor: Colors.red.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radius10Px),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: dangerColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title.tr(),
                  style: const TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: dangerColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.red.withOpacity(0.30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  final BaseTheme baseTheme;
  final Color? color;

  const _TileDivider({required this.baseTheme, this.color});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 66,
      endIndent: 0,
      color: color ?? baseTheme.textColor.fixedOpacity(0.05),
    );
  }
}
