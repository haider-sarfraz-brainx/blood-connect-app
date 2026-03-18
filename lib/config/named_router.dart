import 'package:flutter/material.dart';
import 'package:training_projects/presentation/authentication/onboarding/onboarding_screen.dart';
import 'package:training_projects/presentation/authentication/signin/sign_in_screen.dart';
import 'package:training_projects/presentation/authentication/signup/sign_up_screen.dart';
import '../presentation/authentication/spalsh/splash_screen.dart';
import '../presentation/authentication/welcome/welcome_screen.dart';
import '../presentation/home/navbar/bottom_navbar_screen.dart';
import '../presentation/home/setting/change_password_screen.dart';
import '../presentation/home/setting/edit_profile_screen.dart';
import '../presentation/home/setting/edit_onboarding_screen.dart';

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

}
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());
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
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No Route ${settings.name}')),
          ),
        );
    }
  }
}
