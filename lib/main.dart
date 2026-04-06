import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bloc/language_bloc/language_bloc.dart';
import 'bloc/theme_bloc/theme_bloc.dart';
import 'config/named_router.dart';
import 'core/constants/app_assets.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/local/language.dart';
import 'data/managers/remote/firebase_notification_service.dart';
import 'data/repositories/local/theme.dart';
import 'core/firebase/firebase_background_handler.dart';
import 'injection_container.dart';
import 'config/languages/language_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/authentication_bloc/authentication_bloc.dart';
import 'bloc/authentication_bloc/authentication_states.dart';


final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: '.env');
  await initializeDependencies();
  await sl<FirebaseNotificationService>().initialize();
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: LanguageConfig.locales,
      path: AppAssets.translations,
      fallbackLocale: AppConstants.fallbackLocale,
      useOnlyLangCode: true,
      startLocale: AppConstants.fallbackLocale,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LanguageBloc>(
            create: (context) => LanguageBloc(sl<LanguageRepo>()),
          ),
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc(sl<ThemeRepo>()),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeBloc = context.watch<ThemeBloc>();
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Quick Blood',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      color: themeBloc.state.baseTheme.primary,
      theme: themeBloc.state.baseTheme.themeData,
      initialRoute: RouteNames.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
      builder: (context, child) {
        return BlocListener<AuthenticationBloc, AuthenticationState>(
          bloc: sl<AuthenticationBloc>(),
          listener: (context, state) {
            if (state is AuthenticationPasswordRecovery) {
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                RouteNames.updatePassword,
                (route) => false,
              );
            }
          },
          child: child!,
        );
      },
    );
  }
}
