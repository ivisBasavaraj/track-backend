import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ui/app_theme.dart';
import '../widgets/notification_center.dart';
import 'notification_provider.dart';

class NotificationOverlay extends StatelessWidget {
  final Widget child;
  final bool showBadgeOnly;
  final bool showNotificationCenter;

  const NotificationOverlay({
    super.key,
    required this.child,
    this.showBadgeOnly = false,
    this.showNotificationCenter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showNotificationCenter)
          Positioned(
            top: 80,
            right: 16,
            child: _buildNotificationCenter(context),
          ),
        Positioned(
          top: 16,
          right: 16,
          child: _buildNotificationButton(context),
        ),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notificationProvider.unreadCount;

    return GestureDetector(
      onTap: () {
        // Show notification panel or navigate to notifications screen
        _showNotificationPanel(context);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 28,
              color: unreadCount > 0 ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            if (unreadCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: NotificationBadge(count: unreadCount),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCenter(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadNotifications = notificationProvider.unreadNotifications;

        if (unreadNotifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 320,
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications (${unreadNotifications.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          notificationProvider.markAllAsRead();
                        },
                        tooltip: 'Mark all as read',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: NotificationCenter(
                    showUnreadOnly: true,
                    maxNotifications: 5,
                    onNotificationTap: (notification) {
                      notificationProvider.markAsRead(notification.id);
                      // Navigate to the appropriate screen if available
                      if (notification.screenRoute != null &&
                          notification.screenRoute!.isNotEmpty) {
                        // Navigator.pushNamed(context, notification.screenRoute!);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'All Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: NotificationCenter(
                  showUnreadOnly: false,
                  onNotificationTap: (notification) {
                    final notificationProvider =
                        Provider.of<NotificationProvider>(context, listen: false);
                    notificationProvider.markAsRead(notification.id);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NotificationFloatingButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const NotificationFloatingButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final unreadCount = notificationProvider.unreadCount;

    return FloatingActionButton(
      onPressed: onPressed ?? () => _showNotificationPanel(context),
      backgroundColor: unreadCount > 0 ? Colors.red : Colors.blue,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          const Icon(Icons.notifications, color: Colors.white),
          if (unreadCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: NotificationBadge(
                count: unreadCount,
                showZero: false,
              ),
            ),
        ],
      ),
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: NotificationCenter(
                  showUnreadOnly: false,
                  onNotificationTap: (notification) {
                    final notificationProvider =
                        Provider.of<NotificationProvider>(context, listen: false);
                    notificationProvider.markAsRead(notification.id);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}