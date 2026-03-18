import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:training_projects/config/app_router.dart';
import 'package:training_projects/core/constants/app_constants.dart';
import 'package:training_projects/core/constants/view_constants.dart';
import 'package:training_projects/utils/app_asset.dart';
import 'package:training_projects/widgets/custom_text.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_events.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/named_router.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../injection_container.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  ThemeBloc themeBloc = sl<ThemeBloc>();
  AuthenticationBloc authenticationBloc = sl<AuthenticationBloc>();
  SessionManager sessionManager = sl<SessionManager>();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((callback) {
      initializeComponent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      bloc: authenticationBloc,
      listener: (context, state) {
        if (state is AuthenticationAuthenticated) {
          // Check if onboarding is completed using userModel from state or session
          final user = state.userModel ?? sessionManager.getUser();
          if (user != null && user.isOnboardingCompleted) {
            AppRouter.pushNamedAndRemoveUntil(context, RouteNames.bottomNavbar);
          } else {
            AppRouter.pushNamedAndRemoveUntil(context, RouteNames.onboarding);
          }
        } else if (state is AuthenticationUnauthenticated) {
          AppRouter.pushNamedAndRemoveUntil(context, RouteNames.welcome);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: AppConstants.gap20Px,
              children: [
                SvgPicture.asset(
                  AppAsset.bloodDonationIcon,
                  width: size.width * 0.35,
                ),
                CustomText(
                  text: ViewConstants.bloodConnect,
                  weight: FontWeight.w800,
                  textColor: themeBloc.state.baseTheme.primary,
                  size: AppConstants.font28Px,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void initializeComponent() {
    Future.delayed(const Duration(seconds: 2), () {
      authenticationBloc.add(const CheckAuthenticationStatusEvent());
    });
  }
}
