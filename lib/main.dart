import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'bloc/language_bloc/language_bloc.dart';
import 'bloc/theme_bloc/theme_bloc.dart';
import 'config/named_router.dart';
import 'core/constants/app_assets.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/local/language.dart';
import 'data/repositories/local/theme.dart';
import 'injection_container.dart';
import 'config/languages/language_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await initializeDependencies();
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
      title: 'Blood Connect App',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      color: themeBloc.state.baseTheme.primary,
      theme: themeBloc.state.baseTheme.themeData,
      initialRoute: RouteNames.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

