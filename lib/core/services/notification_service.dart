import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background FCM message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'reshme_channel',
    'Reshme Market Alerts',
    description: 'Real-time cocoon price updates and sericulture advisories',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    try {
      // 1. Create Android Notification Channel
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_channel);

      // 2. Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(initSettings);

      // 3. Request permissions on Android 13+ & FCM
      if (Platform.isAndroid) {
        await androidPlugin?.requestNotificationsPermission();
      }

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 4. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. Fetch & Save Device Token
      await syncDeviceToken();

      // 6. Subscribe to universal broadcast topic
      try {
        await _messaging.subscribeToTopic('all');
        debugPrint('Subscribed to FCM topic: all');
      } catch (topicErr) {
        debugPrint('Topic subscription error: $topicErr');
      }

      // 7. Auto-refresh token listener
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToSupabase(newToken);
      });

      // 8. Foreground message listener (Show banner)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });
    } catch (e) {
      debugPrint('Notification service initialization notice: $e');
    }
  }

  /// Subscribe device to a specific APMC market topic (e.g. market_Sidlaghatta)
  static Future<void> subscribeToMarket(String marketName) async {
    try {
      final sanitized = marketName.replaceAll(RegExp(r'\s+'), '_');
      await _messaging.subscribeToTopic('market_$sanitized');
      debugPrint('Subscribed to market topic: market_$sanitized');
    } catch (e) {
      debugPrint('Market subscription note: $e');
    }
  }

  /// Unsubscribe device from a specific market topic
  static Future<void> unsubscribeFromMarket(String marketName) async {
    try {
      final sanitized = marketName.replaceAll(RegExp(r'\s+'), '_');
      await _messaging.unsubscribeFromTopic('market_$sanitized');
      debugPrint('Unsubscribed from market topic: market_$sanitized');
    } catch (e) {
      debugPrint('Market unsubscription note: $e');
    }
  }

  static Future<void> syncDeviceToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Registration Token: $token');
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  static Future<void> _saveTokenToSupabase(String token) async {
    try {
      final client = Supabase.instance.client;
      await client.from('push_tokens').upsert(
        {
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'token',
      );
      debugPrint('FCM Token successfully synced to Supabase: $token');
    } catch (e) {
      debugPrint('Failed to save FCM token to Supabase: $e');
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      final details = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        message.hashCode,
        notification.title ?? 'Reshme Price Alert',
        notification.body ?? '',
        details,
      );
    } catch (e) {
      debugPrint('Foreground notification display notice: $e');
    }
  }
}
