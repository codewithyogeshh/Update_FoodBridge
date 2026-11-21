import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../domain/models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _kStorageKey = 'foodbridge_persisted_notifications_v1';
  final List<AppNotification> _notifications = [];
  final Set<String> _sentEventFingerprints = {};
  NotificationPreferences _preferences = const NotificationPreferences();
  final bool _isLoading = false;

  NotificationProvider({bool seedInitial = true}) {
    _loadPersistedNotifications(seedInitial: seedInitial);
  }

  List<AppNotification> get allNotifications => List.unmodifiable(_notifications);
  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unreadNotifications.length;
  NotificationPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;

  Future<void> _loadPersistedNotifications({bool seedInitial = false}) async {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        if (seedInitial) _seedInitialNotifications();
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _notifications.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            _notifications.add(AppNotification.fromJson(item));
          } else if (item is Map) {
            _notifications.add(AppNotification.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        for (final n in _notifications) {
          _sentEventFingerprints.add('${n.type.name}_${n.relatedDonationId ?? ""}_${n.title}');
        }
        notifyListeners();
      } else if (seedInitial) {
        _seedInitialNotifications();
        await _persistNotifications();
      }
    } catch (_) {
      if (seedInitial && _notifications.isEmpty) {
        _seedInitialNotifications();
      }
    }
  }

  Future<void> _persistNotifications() async {
    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;
      final prefs = await SharedPreferences.getInstance();
      final list = _notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_kStorageKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Dispatch a realtime notification event with deduplication guard
  bool dispatchRealtimeEvent({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedDonationId,
    String? actionRoute,
  }) {
    // 1. Check user notification preferences
    if (type == NotificationType.deadlineWarning && !_preferences.deadlineAlerts) {
      return false;
    }
    if (type == NotificationType.newDonation && !_preferences.nearbyDonationsAlerts) {
      return false;
    }
    if (!_preferences.statusChangeAlerts &&
        (type == NotificationType.volunteerAssigned ||
            type == NotificationType.pickupConfirmed ||
            type == NotificationType.deliveryConfirmed)) {
      return false;
    }

    // 2. Deduplication check: prevent identical repeated notifications within a session
    final fingerprint = '${type.name}_${relatedDonationId ?? ""}_$title';
    if (_sentEventFingerprints.contains(fingerprint)) {
      return false; // Suppress duplicate
    }
    _sentEventFingerprints.add(fingerprint);

    final notification = AppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}-${_notifications.length}',
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
      relatedDonationId: relatedDonationId,
      actionRoute: actionRoute,
    );

    _notifications.insert(0, notification);
    _persistNotifications();
    NotificationService.instance.showSystemNotification(
      title: title,
      body: message,
      payload: relatedDonationId ?? actionRoute,
    );
    notifyListeners();
    return true;
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _persistNotifications();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      _persistNotifications();
      notifyListeners();
    }
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _persistNotifications();
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    _sentEventFingerprints.clear();
    _persistNotifications();
    notifyListeners();
  }

  void updatePreferences(NotificationPreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
  }

  void _seedInitialNotifications() {
    final now = DateTime.now();
    _notifications.addAll([
      AppNotification(
        id: 'notif-1',
        title: 'Donation Claimed!',
        message: 'Asha Children Foundation claimed 50 Veg Biryani Meal Boxes.',
        type: NotificationType.ngoRequest,
        timestamp: now.subtract(const Duration(minutes: 5)),
        isRead: false,
        relatedDonationId: 'dn-101',
        actionRoute: '/donation-detail/dn-101',
      ),
      AppNotification(
        id: 'notif-2',
        title: 'Volunteer Courier Dispatched',
        message: 'Rohit Kulkarni accepted dispatch and is on the way for pickup.',
        type: NotificationType.volunteerAssigned,
        timestamp: now.subtract(const Duration(minutes: 18)),
        isRead: false,
        relatedDonationId: 'dn-102',
        actionRoute: '/donation-detail/dn-102',
      ),
      AppNotification(
        id: 'notif-3',
        title: 'Cargo Picked Up',
        message: 'Physical pickup confirmed via OTP. Rider is in-transit to shelter.',
        type: NotificationType.pickupConfirmed,
        timestamp: now.subtract(const Duration(minutes: 42)),
        isRead: true,
        relatedDonationId: 'dn-102',
        actionRoute: '/donation-detail/dn-102',
      ),
      AppNotification(
        id: 'notif-4',
        title: 'New Donation Available',
        message: 'The Green Leaf Bistro listed 50 meal boxes in Powai Naka, Satara.',
        type: NotificationType.newDonation,
        timestamp: now.subtract(const Duration(hours: 1)),
        isRead: true,
        relatedDonationId: 'dn-101',
        actionRoute: '/donation-detail/dn-101',
      ),
    ]);

    for (final n in _notifications) {
      _sentEventFingerprints.add('${n.type.name}_${n.relatedDonationId ?? ""}_${n.title}');
    }
  }
}

