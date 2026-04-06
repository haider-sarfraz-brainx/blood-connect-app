import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'languages/language.dart';
import 'languages/language_config.dart';

class Config {

  static const String english = 'english';
  static const String urdu = 'urdu';

  static const String light = 'light';
  static const String dark = 'dark';

  static const String fontMontserratFamily = 'Montserrat';
  static const String fontLatoFamily = 'Lato';
  static const String defaultTheme = light;
  static final Language defaultLanguage = LanguageConfig.defaultLanguage(english);
  static const double designScreenHeight = 812.0;
  static const double designScreenWidth = 375.0;

  
  static const String bundleId = '';
  static const String appleId = '';
  static const String appPlaystoreUrl =
      'https://play.google.com/store/apps/details?id=$bundleId';
  static const String appAppstoreUrl = 'https://apps.apple.com/app/id$appleId';
  
  static const String privacyPolicyUrl = '';
  static const String termsOfUseUrl = '';
  static const String contactUsEmail = '';
  
  static String get fcmServerKey => dotenv.env['FIREBASE_SERVER_KEY'] ?? '';

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// Firebase / FCM — optional until you add keys to `.env` and platform config files.
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseAndroidApiKey =>
      dotenv.env['FIREBASE_ANDROID_API_KEY'] ?? '';
  static String get firebaseAndroidAppId =>
      dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  static String get firebaseIosApiKey =>
      dotenv.env['FIREBASE_IOS_API_KEY'] ?? '';
  static String get firebaseIosAppId =>
      dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  static String get firebaseIosBundleId =>
      dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '';

}
