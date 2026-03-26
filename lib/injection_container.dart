import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart' as sp;
import 'bloc/authentication_bloc/authentication_bloc.dart';
import 'bloc/blood_request_bloc/blood_request_bloc.dart';
import 'bloc/language_bloc/language_bloc.dart';
import 'bloc/messaging_bloc/messaging_bloc.dart';
import 'bloc/theme_bloc/theme_bloc.dart';
import 'config/config.dart';
import 'core/services/location_service.dart';
import 'data/managers/local/local_storage.dart';
import 'data/managers/local/session_manager.dart';
import 'data/managers/local/shared_preference.dart';
import 'data/managers/remote/supabase_service.dart';
import 'data/repositories/local/language.dart';
import 'data/repositories/local/theme.dart';
import 'data/repositories/remote/authentication/authentication_repository.dart';
import 'data/repositories/remote/messaging/messaging_repository.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  await SupabaseService.initialize(
    supabaseUrl: Config.supabaseUrl,
    supabaseAnonKey: Config.supabaseAnonKey,
  );

  final sharedPreferences = await sp.SharedPreferences.getInstance();
  sl.registerSingleton<sp.SharedPreferences>(sharedPreferences);
  sl.registerSingleton<LocalStorageManager>(SharedPreferenceManager(sl<sp.SharedPreferences>()));
  sl.registerSingleton<SessionManager>(SessionManager(sl<LocalStorageManager>()));

  sl.registerSingleton<SupabaseService>(SupabaseService());

  sl.registerSingleton<ThemeRepo>(ThemeRepo(sl<LocalStorageManager>()));
  sl.registerSingleton<LanguageRepo>(LanguageRepo(sl<LocalStorageManager>()));
  sl.registerSingleton<AuthenticationRepository>(
    AuthenticationRepository(sl<SupabaseService>()),
  );
  sl.registerSingleton<MessagingRepository>(
    MessagingRepository(sl<SupabaseService>()),
  );

  sl.registerSingleton<LanguageBloc>(LanguageBloc(sl<LanguageRepo>()));
  sl.registerSingleton<ThemeBloc>(ThemeBloc(sl<ThemeRepo>()));
  sl.registerLazySingleton<AuthenticationBloc>(
    () => AuthenticationBloc(sl<AuthenticationRepository>()),
  );
  sl.registerLazySingleton<BloodRequestBloc>(
    () => BloodRequestBloc(sl<SupabaseService>()),
  );
  
  sl.registerLazySingleton<MessagingBloc>(
    () => MessagingBloc(
      messagingRepository: sl<MessagingRepository>(),
      currentUserId: sl<SessionManager>().getUser()?.id ?? '',
    ),
  );

  sl.registerSingleton<LocationService>(LocationService());
}
