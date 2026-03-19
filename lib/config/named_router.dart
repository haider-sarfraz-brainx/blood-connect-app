import 'package:flutter/material.dart';
import 'package:quick_blood/presentation/authentication/onboarding/onboarding_screen.dart';
import 'package:quick_blood/presentation/authentication/signin/sign_in_screen.dart';
import 'package:quick_blood/presentation/authentication/signup/sign_up_screen.dart';
import '../presentation/authentication/spalsh/splash_screen.dart';
import '../presentation/authentication/welcome/welcome_screen.dart';
import '../presentation/home/navbar/bottom_navbar_screen.dart';
import '../presentation/home/setting/change_password_screen.dart';
import '../presentation/home/setting/edit_profile_screen.dart';
import '../presentation/home/setting/edit_onboarding_screen.dart';
import '../presentation/authentication/forgot_password/forgot_password_screen.dart';
import '../presentation/authentication/forgot_password/update_password_screen.dart';

class RouteNames {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String signup = '/signup';
  static const String signIn = '/signIn';
  static const String onboarding = '/onboarding';
  static const String bottomNavbar = '/bottomNavbar';
  static const String editProfile = '/editProfile';
  static const String editOnboarding = '/editOnboarding';
  static const String changePassword = '/changePassword';
  static const String forgotPassword = '/forgotPassword';
  static const String updatePassword = '/updatePassword';

}
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    String routeName = settings.name ?? '';
    String? deepLinkError;

    if (routeName.startsWith('/?')) {
      try {
        Uri uri = Uri.parse(routeName);
        if (uri.queryParameters.containsKey('error_description')) {
          deepLinkError = uri.queryParameters['error_description']?.replaceAll('+', ' ');
        } else if (uri.fragment.contains('error_description=')) {
          final fragmentUri = Uri.parse('?${uri.fragment}');
          deepLinkError = fragmentUri.queryParameters['error_description']?.replaceAll('+', ' ');
        }
      } catch (_) {}
      routeName = RouteNames.splash;
    }

    switch (routeName) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen(deepLinkError: deepLinkError));
      case RouteNames.welcome:
        return MaterialPageRoute(builder: (_) => WelcomeScreen());
      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => SignUpScreen());
      case RouteNames.signIn:
        return MaterialPageRoute(builder: (_) => SignInScreen());
      case RouteNames.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case RouteNames.bottomNavbar:
        return MaterialPageRoute(builder: (_) => BottomNavbarScreen());
      case RouteNames.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case RouteNames.editOnboarding:
        return MaterialPageRoute(builder: (_) => const EditOnboardingScreen());
      case RouteNames.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case RouteNames.updatePassword:
        return MaterialPageRoute(builder: (_) => const UpdatePasswordScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No Route ${settings.name}')),
          ),
        );
    }
  }
}
