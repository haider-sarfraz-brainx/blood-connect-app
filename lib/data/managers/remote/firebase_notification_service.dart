import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/config.dart';
import '../../../core/firebase/default_firebase_options.dart';
import 'supabase_service.dart';

import '../local/session_manager.dart';


/// Firebase Cloud Messaging: permissions, token sync to Supabase `users.fcm_token`,
/// foreground display via local notifications, and background entry setup.
class FirebaseNotificationService {
  FirebaseNotificationService(this._supabase, this._session);
 
  final SupabaseService _supabase;
  final SessionManager _session;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final Dio _dio = Dio();



  static const _channelId = 'high_importance_channel';
  static const _channelName = 'Push notifications';

  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<AuthState>? _authSub;

  Future<void> initialize() async {
    if (!isFirebaseConfigured) {
      debugPrint(
        'FirebaseNotificationService: skipped (add FIREBASE_* keys to .env)',
      );
      return;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: defaultFirebaseOptions());
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _setupLocalNotifications();
    await _requestPermissions();

    await _syncTokenIfLoggedIn();

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _persistToken(token),
      onError: (err) {
        debugPrint('FirebaseNotificationService: onTokenRefresh error: $err');
      },
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    _authSub = _supabase.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        final token = await FirebaseMessaging.instance.getToken();
        await _persistToken(token);
      }
    });
  }

  Future<void> _setupLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Blood request and chat alerts',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _syncTokenIfLoggedIn() async {
    final uid = _supabase.client.auth.currentUser?.id;
    if (uid == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    await _persistToken(token);
  }

  Future<void> _persistToken(String? token) async {
    final uid = _supabase.client.auth.currentUser?.id;
    if (uid == null || token == null || token.isEmpty) return;

    // Update local session
    final currentUser = _session.getUser();
    if (currentUser != null && currentUser.fcmToken != token) {
      await _session.saveUser(currentUser.copyWith(fcmToken: token));
    }

    try {
      await _supabase.updateUserFcmToken(uid, token);
    } catch (e, st) {
      debugPrint('FCM token sync failed: $e\n$st');
    }
  }


  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    final id = message.messageId?.hashCode.abs() ??
        DateTime.now().millisecondsSinceEpoch.remainder(1 << 30);

    _local.show(
      id: id,
      title: n.title ?? 'Quick Blood',
      body: n.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Blood request and chat alerts',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId} ${message.data}');
  }

  /// Sends a push notification via FCM REST API (legacy).
  /// Note: This requires FIREBASE_SERVER_KEY in .env.
  /// For production, prefer using a backend / cloud function.
  Future<void> sendPushNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final serverKey = Config.fcmServerKey;
    if (serverKey.isEmpty) {
      debugPrint('sendPushNotification: skipped (FIREBASE_SERVER_KEY missing)');
      return;
    }

    try {
      await _dio.post(
        'https://fcm.googleapis.com/fcm/send',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
        ),
        data: {
          'to': recipientToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data ?? {},
        },
      );
      debugPrint('Push notification sent to $recipientToken');
    } catch (e) {
      debugPrint('Push notification failed: $e');
    }
  }


  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _authSub?.cancel();
  }
}
