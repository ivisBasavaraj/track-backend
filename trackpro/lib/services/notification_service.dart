import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/tool_life_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final List<Function(AppNotification)> _notificationListeners = [];

  // Add a notification listener
  void addNotificationListener(Function(AppNotification) listener) {
    _notificationListeners.add(listener);
  }

  // Remove a notification listener
  void removeNotificationListener(Function(AppNotification) listener) {
    _notificationListeners.remove(listener);
  }

  // Get all notifications
  List<AppNotification> getAllNotifications() {
    return List.from(_notifications);
  }

  // Get unread notifications
  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notifyListeners(_notifications[index]);
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        _notifyListeners(_notifications[i]);
        changed = true;
      }
    }
    if (changed) {
      _notifyAllListeners();
    }
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    _notifyAllListeners();
  }

  // Show tool life alert notification
  void showToolLifeAlertNotification(ToolAlert alert) {
    final notification = AppNotification(
      id: 'tool_${alert.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: _getToolAlertTitle(alert),
      message: _getToolAlertMessage(alert),
      type: NotificationType.toolLife,
      severity: _mapAlertSeverity(alert.alertSeverity),
      timestamp: DateTime.now(),
      payload: {
        'alert_id': alert.id,
        'tool_id': alert.toolId,
        'tool_name': alert.toolName,
        'severity': alert.alertSeverity,
      },
      screenRoute: '/tool_alerts',
      icon: _getAlertIcon(alert.alertSeverity),
    );

    _addAndNotify(notification);
  }

  // Show stock monitoring notification
  void showStockMonitoringNotification({
    required String toolName,
    required int currentStock,
    required int threshold,
    required bool isCritical,
  }) {
    final notification = AppNotification(
      id: 'stock_${toolName}_${DateTime.now().millisecondsSinceEpoch}',
      title: isCritical ? '🚨 Critical Stock Alert' : '⚠️ Stock Warning',
      message: '$toolName stock: $currentStock units (threshold: $threshold)',
      type: NotificationType.stockMonitoring,
      severity: isCritical ? NotificationSeverity.critical : NotificationSeverity.warning,
      timestamp: DateTime.now(),
      payload: {
        'tool_name': toolName,
        'current_stock': currentStock,
        'threshold': threshold,
        'is_critical': isCritical,
      },
      screenRoute: '/tool_stock',
      icon: isCritical ? '🚨' : '⚠️',
    );

    _addAndNotify(notification);
  }

  // Show process status notification
  void showProcessStatusNotification({
    required String processName,
    required String status,
    required String message,
    bool isCritical = false,
  }) {
    final notification = AppNotification(
      id: 'process_${processName}_${DateTime.now().millisecondsSinceEpoch}',
      title: isCritical ? '🚨 $processName Critical' : 'ℹ️ $processName Update',
      message: message,
      type: NotificationType.processStatus,
      severity: isCritical ? NotificationSeverity.critical : NotificationSeverity.info,
      timestamp: DateTime.now(),
      payload: {
        'process_name': processName,
        'status': status,
        'message': message,
        'is_critical': isCritical,
      },
      screenRoute: '/process_monitoring',
      icon: isCritical ? '🚨' : 'ℹ️',
    );

    _addAndNotify(notification);
  }

  // Show system alert notification
  void showSystemAlertNotification({
    required String title,
    required String message,
    String severity = NotificationSeverity.warning,
    String? screenRoute,
  }) {
    final notification = AppNotification(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: NotificationType.systemAlert,
      severity: severity,
      timestamp: DateTime.now(),
      payload: {
        'title': title,
        'message': message,
      },
      screenRoute: screenRoute,
      icon: severity == NotificationSeverity.critical ? '🚨' :
            severity == NotificationSeverity.warning ? '⚠️' : 'ℹ️',
    );

    _addAndNotify(notification);
  }

  // Helper methods
  String _getToolAlertTitle(ToolAlert alert) {
    switch (alert.alertSeverity) {
      case 'CRITICAL':
        return '🚨 CRITICAL TOOL ALERT';
      case 'WARNING':
        return '⚠️ TOOL WARNING';
      default:
        return 'ℹ️ TOOL NOTIFICATION';
    }
  }

  String _getToolAlertMessage(ToolAlert alert) {
    return '${alert.toolName} - ${alert.alertType} '
        '(Usage: ${alert.usagePercentage.toStringAsFixed(1)}%)';
  }

  String _mapAlertSeverity(String alertSeverity) {
    switch (alertSeverity) {
      case 'CRITICAL':
        return NotificationSeverity.critical;
      case 'WARNING':
        return NotificationSeverity.warning;
      default:
        return NotificationSeverity.info;
    }
  }

  String _getAlertIcon(String alertSeverity) {
    switch (alertSeverity) {
      case 'CRITICAL':
        return '🚨';
      case 'WARNING':
        return '⚠️';
      default:
        return 'ℹ️';
    }
  }

  // Internal methods
  void _addAndNotify(AppNotification notification) {
    _notifications.insert(0, notification); // Add to beginning for newest first
    _notifyListeners(notification);
    _notifyAllListeners();
  }

  void _notifyListeners(AppNotification notification) {
    for (final listener in _notificationListeners) {
      try {
        listener(notification);
      } catch (e) {
        debugPrint('Error notifying listener: $e');
      }
    }
  }

  void _notifyAllListeners() {
    // Create a snapshot to avoid issues with listeners being added/removed during iteration
    final listeners = List.from(_notificationListeners);
    for (final listener in listeners) {
      try {
        // Notify with the latest notification or null to indicate refresh
        if (_notifications.isNotEmpty) {
          listener(_notifications.first);
        }
      } catch (e) {
        debugPrint('Error notifying listener: $e');
      }
    }
  }
}