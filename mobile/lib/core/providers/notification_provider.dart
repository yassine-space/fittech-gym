// lib/core/providers/notification_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile/core/services/apiservice.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String type; // waitlist_promotion | subscription_expiry | coach_assignment | new_message
  final String title;
  final String body;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) =>
      AppNotification(
        id: j['id'] ?? '',
        type: j['notification_type'] ?? 'new_message',
        title: j['title'] ?? '',
        body: j['body'] ?? '',
        isRead: j['is_read'] ?? false,
        createdAt:
            DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationProvider
// ─────────────────────────────────────────────────────────────────────────────

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Timer? _pollTimer;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  // ─────────────────────────────────────────────────────────────────────────
  // Load
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final res = await Apiservice.instance
          .request(DioMethode.get, '/notifications/');
      final List data = res.data;
      _notifications =
          data.map((j) => AppNotification.fromJson(j)).toList();
    } catch (e) {
      if (!silent) _error = 'Failed to load notifications';
    } finally {
      if (!silent) _loading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mark single as read
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> markRead(String id) async {
    // Optimistic
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && _notifications[idx].isRead) return;
    if (idx != -1) _notifications[idx].isRead = true;
    notifyListeners();

    try {
      await Apiservice.instance
          .request(DioMethode.patch, '/notifications/$id/read/');
    } catch (_) {
      // Revert on failure
      if (idx != -1) _notifications[idx].isRead = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mark all as read
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> markAllRead() async {
    // Optimistic
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();

    try {
      await Apiservice.instance
          .request(DioMethode.patch, '/notifications/read-all/');
    } catch (_) {
      // Reload to revert
      await load(silent: true);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Polling (every 30s for new notifications while app is open)
  // ─────────────────────────────────────────────────────────────────────────

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => load(silent: true));
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  List<AppNotification> get unread =>
      _notifications.where((n) => !n.isRead).toList();

  List<AppNotification> get read =>
      _notifications.where((n) => n.isRead).toList();

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}