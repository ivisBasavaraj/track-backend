import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/tool_life_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isInitialized = false;

  NotificationProvider() {
    _initialize();
  }

  void _initialize() {
    if (!_isInitialized) {
      _notifications = _notificationService.getAllNotifications();
      _notificationService.addNotificationListener(_handleNewNotification);
      _isInitialized = true;
    }
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<AppNotification> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void _handleNewNotification(AppNotification notification) {
    // Check if notification already exists
    final existingIndex = _notifications.indexWhere((n) => n.id == notification.id);

    if (existingIndex != -1) {
      // Update existing notification
      _notifications[existingIndex] = notification;
    } else {
      // Add new notification
      _notifications.insert(0, notification);
    }

    notifyListeners();
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
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
      notifyListeners();
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void showToolLifeAlertNotification(ToolAlert alert) {
    _notificationService.showToolLifeAlertNotification(alert);
  }

  void showStockMonitoringNotification({
    required String toolName,
    required int currentStock,
    required int threshold,
    required bool isCritical,
  }) {
    _notificationService.showStockMonitoringNotification(
      toolName: toolName,
      currentStock: currentStock,
      threshold: threshold,
      isCritical: isCritical,
    );
  }

  void showProcessStatusNotification({
    required String processName,
    required String status,
    required String message,
    bool isCritical = false,
  }) {
    _notificationService.showProcessStatusNotification(
      processName: processName,
      status: status,
      message: message,
      isCritical: isCritical,
    );
  }

  void showSystemAlertNotification({
    required String title,
    required String message,
    String severity = NotificationSeverity.warning,
    String? screenRoute,
  }) {
    _notificationService.showSystemAlertNotification(
      title: title,
      message: message,
      severity: severity,
      screenRoute: screenRoute,
    );
  }

  @override
  void dispose() {
    _notificationService.removeNotificationListener(_handleNewNotification);
    super.dispose();
  }
}

class NotificationWrapper extends StatelessWidget {
  final Widget child;

  const NotificationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => NotificationProvider(),
      child: child,
    );
  }
}