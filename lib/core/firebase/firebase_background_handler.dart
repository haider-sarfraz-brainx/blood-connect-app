import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'default_firebase_options.dart';

/// Must be a top-level function registered before [Firebase.initializeApp] in [main].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!isFirebaseConfigured) return;
  await Firebase.initializeApp(options: defaultFirebaseOptions());
}
