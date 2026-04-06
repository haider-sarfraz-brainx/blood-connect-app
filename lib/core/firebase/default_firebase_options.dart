import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

import '../../config/config.dart';

/// Builds [FirebaseOptions] from `.env` when Firebase is configured.
/// Add the keys from your Firebase project settings (or run `flutterfire configure`
/// and replace this file with the generated `firebase_options.dart`).
bool get isFirebaseConfigured {
  if (kIsWeb) return false;
  if (Config.firebaseProjectId.isEmpty ||
      Config.firebaseMessagingSenderId.isEmpty) {
    return false;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return Config.firebaseAndroidApiKey.isNotEmpty &&
          Config.firebaseAndroidAppId.isNotEmpty;
    case TargetPlatform.iOS:
      return Config.firebaseIosApiKey.isNotEmpty &&
          Config.firebaseIosAppId.isNotEmpty;
    default:
      return false;
  }
}

FirebaseOptions defaultFirebaseOptions() {
  if (kIsWeb) {
    throw UnsupportedError(
      'Firebase is not configured for web in this project.',
    );
  }
  final bucket = Config.firebaseStorageBucket.isNotEmpty
      ? Config.firebaseStorageBucket
      : '${Config.firebaseProjectId}.appspot.com';

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return FirebaseOptions(
        apiKey: Config.firebaseAndroidApiKey,
        appId: Config.firebaseAndroidAppId,
        messagingSenderId: Config.firebaseMessagingSenderId,
        projectId: Config.firebaseProjectId,
        storageBucket: bucket,
      );
    case TargetPlatform.iOS:
      return FirebaseOptions(
        apiKey: Config.firebaseIosApiKey,
        appId: Config.firebaseIosAppId,
        messagingSenderId: Config.firebaseMessagingSenderId,
        projectId: Config.firebaseProjectId,
        storageBucket: bucket,
        iosBundleId: Config.firebaseIosBundleId.isNotEmpty
            ? Config.firebaseIosBundleId
            : null,
      );
    default:
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      );
  }
}
