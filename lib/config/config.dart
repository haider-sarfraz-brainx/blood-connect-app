import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'languages/language.dart';
import 'languages/language_config.dart';

class Config {

// Languages
  static const String english = 'english';
  static const String urdu = 'urdu';

// Themes
  static const String light = 'light';
  static const String dark = 'dark';

  // Config
  static const String fontMontserratFamily = 'Montserrat';
  static const String fontLatoFamily = 'Lato';
  static const String defaultTheme = light;
  static final Language defaultLanguage = LanguageConfig.defaultLanguage(english);
  static const double designScreenHeight = 812.0;
  static const double designScreenWidth = 375.0;
  // TODO: Add your own bundle id and apple id
  // Example: bundleId = 'com.example.app';
  // Example: appleId = '1234567890';
  static const String bundleId = '';
  static const String appleId = '';
  static const String appPlaystoreUrl =
      'https://play.google.com/store/apps/details?id=$bundleId';
  static const String appAppstoreUrl = 'https://apps.apple.com/app/id$appleId';
  // TODO: Add your own privacy policy url and terms of use url and contact us email
  static const String privacyPolicyUrl = '';
  static const String termsOfUseUrl = '';
  static const String contactUsEmail = '';

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

}
