import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../ui/app_theme.dart';

class NotificationCenter extends StatefulWidget {
  final bool showUnreadOnly;
  final int maxNotifications;
  final Function(AppNotification)? onNotificationTap;
  final Function(String)? onDismiss;

  const NotificationCenter({
    super.key,
    this.showUnreadOnly = true,
    this.maxNotifications = 5,
    this.onNotificationTap,
    this.onDismiss,
  });

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _notificationService.addNotificationListener(_handleNewNotification);
  }

  @override
  void dispose() {
    _notificationService.removeNotificationListener(_handleNewNotification);
    super.dispose();
  }

  void _loadNotifications() {
    setState(() {
      _isLoading = true;
    });

    final notifications = widget.showUnreadOnly
        ? _notificationService.getUnreadNotifications()
        : _notificationService.getAllNotifications();

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  void _handleNewNotification(AppNotification notification) {
    if (mounted) {
      setState(() {
        if (widget.showUnreadOnly && notification.isRead) {
          _notifications.removeWhere((n) => n.id == notification.id);
        } else if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications.insert(0, notification);
          if (_notifications.length > widget.maxNotifications) {
            _notifications = _notifications.sublist(0, widget.maxNotifications);
          }
        }
      });
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    if (widget.onNotificationTap != null) {
      widget.onNotificationTap!(notification);
    } else {
      // Default behavior: mark as read
      _notificationService.markAsRead(notification.id);
    }
  }

  void _handleDismiss(String notificationId) {
    if (widget.onDismiss != null) {
      widget.onDismiss!(notificationId);
    }
    // Remove from local list but don't mark as read
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return AppTheme.errorColor;
      case NotificationSeverity.warning:
        return AppTheme.warningColor;
      case NotificationSeverity.success:
        return AppTheme.successColor;
      case NotificationSeverity.info:
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return Icons.error_outline;
      case NotificationSeverity.warning:
        return Icons.warning_amber_outlined;
      case NotificationSeverity.success:
        return Icons.check_circle_outline;
      case NotificationSeverity.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.showUnreadOnly ? 'No unread notifications' : 'No notifications',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        final severityColor = _getSeverityColor(notification.severity);
        final severityIcon = _getSeverityIcon(notification.severity);

        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppTheme.errorColor.withOpacity(0.1),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
          ),
          onDismissed: (direction) => _handleDismiss(notification.id),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: notification.isRead
                    ? AppTheme.borderColor
                    : severityColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: InkWell(
              onTap: () => _handleNotificationTap(notification),
              borderRadius: BorderRadius.circular(12),
              hoverColor: AppTheme.hoverColor,
              splashColor: AppTheme.primaryLight.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: severityColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        severityIcon,
                        color: severityColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                notification.title,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (!notification.isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.message,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                _formatTimeAgo(notification.timestamp),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              if (notification.icon != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  notification.icon!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationBadge extends StatelessWidget {
  final int count;
  final bool showZero;

  const NotificationBadge({
    super.key,
    required this.count,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0 && !showZero) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.errorColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: AppTheme.bodySmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}