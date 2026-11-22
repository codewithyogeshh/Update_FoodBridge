import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Central Notification Service providing real Android system notifications
/// that appear on the phone screen / notification tray even when app is minimized.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _kChannelId = 'foodbridge_donations_v2';
  static const String _kChannelName = 'FoodBridge Realtime Alerts';
  static const String _kChannelDesc =
      'Instant push notifications for new surplus food and clothing listings';

  /// Initialize local notifications plugin and create notification channels
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInitialized = true;
      return;
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Request permissions on Android 13+ (Tiramisu / API 33+)
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.requestNotificationsPermission();
        }
      }

      _isInitialized = true;
      debugPrint('[NotificationService] Initialized successfully.');
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  /// Display a general system notification on the device screen
  Future<void> showSystemNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) => showNewDonationNotification(
    title: title,
    body: body,
    payload: payload,
    notificationId: notificationId,
  );

  /// Display a high-priority system notification on the device screen
  Future<void> showNewDonationNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final id = notificationId ??
          (payload != null && payload.trim().isNotEmpty
              ? (payload.trim().hashCode.abs() % 90000 + 1000)
              : (DateTime.now().millisecondsSinceEpoch ~/ 1000).remainder(100000));

      const androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'FoodBridge Alert',
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotificationService] Failed to show system notification: $e');
    }
  }
}
