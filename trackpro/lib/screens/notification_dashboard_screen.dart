import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../widgets/notification_center.dart';
import '../widgets/notification_provider.dart';
import '../ui/app_theme.dart';

class NotificationDashboardScreen extends StatefulWidget {
  const NotificationDashboardScreen({super.key});

  @override
  State<NotificationDashboardScreen> createState() => _NotificationDashboardScreenState();
}

class _NotificationDashboardScreenState extends State<NotificationDashboardScreen> {
  int _selectedFilter = 0; // 0: All, 1: Unread, 2: Critical, 3: Tool Life, 4: Stock

  final List<String> _filterOptions = [
    'All',
    'Unread',
    'Critical',
    'Tool Life',
    'Stock',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final allNotifications = notificationProvider.notifications;
          final unreadCount = notificationProvider.unreadCount;

          // Filter notifications based on selection
          List<AppNotification> filteredNotifications;

          switch (_selectedFilter) {
            case 0: // All
              filteredNotifications = allNotifications;
              break;
            case 1: // Unread
              filteredNotifications = allNotifications.where((n) => !n.isRead).toList();
              break;
            case 2: // Critical
              filteredNotifications = allNotifications
                  .where((n) => n.severity == NotificationSeverity.critical)
                  .toList();
              break;
            case 3: // Tool Life
              filteredNotifications = allNotifications
                  .where((n) => n.type == NotificationType.toolLife)
                  .toList();
              break;
            case 4: // Stock
              filteredNotifications = allNotifications
                  .where((n) => n.type == NotificationType.stockMonitoring)
                  .toList();
              break;
            default:
              filteredNotifications = allNotifications;
          }

          return Column(
            children: [
              _buildHeader(notificationProvider, unreadCount),
              _buildFilterChips(),
              const Divider(height: 1),
              Expanded(
                child: filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : NotificationCenter(
                        showUnreadOnly: false,
                        maxNotifications: 50,
                        onNotificationTap: (notification) {
                          notificationProvider.markAsRead(notification.id);
                          // Handle navigation based on notification type
                          _handleNotificationNavigation(context, notification);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildHeader(NotificationProvider notificationProvider, int unreadCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Center',
                  style: AppTheme.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$unreadCount unread notifications',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Mark all as read',
                onPressed: () => notificationProvider.markAllAsRead(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear all',
                onPressed: () => _showClearConfirmation(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filterOptions[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = index;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.1),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.borderColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 0
                  ? 'No notifications yet'
                  : 'No notifications match this filter',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 0
                  ? 'All systems are operating normally'
                  : 'Try changing the filter criteria',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'mark_read',
          backgroundColor: Colors.green,
          onPressed: () {
            final notificationProvider =
                Provider.of<NotificationProvider>(context, listen: false);
            notificationProvider.markAllAsRead();
          },
          child: const Icon(Icons.mark_chat_read_outlined, color: Colors.white),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: 'settings',
          backgroundColor: Colors.blue,
          onPressed: () => _showSettingsDialog(context),
          child: const Icon(Icons.settings_outlined, color: Colors.white),
        ),
      ],
    );
  }

  void _handleNotificationNavigation(
      BuildContext context, AppNotification notification) {
    // Implement navigation logic based on notification type and screenRoute
    if (notification.screenRoute != null && notification.screenRoute!.isNotEmpty) {
      // Navigator.pushNamed(context, notification.screenRoute!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to ${notification.screenRoute}'),
          action: SnackBarAction(
            label: 'DISMISS',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final notificationProvider =
                  Provider.of<NotificationProvider>(context, listen: false);
              notificationProvider.clearAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Configure notification preferences:'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Tool Life Alerts'),
              value: true, // Replace with actual preference
              onChanged: (value) {
                // Implement preference change
              },
            ),
            SwitchListTile(
              title: const Text('Enable Stock Alerts'),
              value: true, // Replace with actual preference
              onChanged: (value) {
                // Implement preference change
              },
            ),
            SwitchListTile(
              title: const Text('Enable Process Alerts'),
              value: true, // Replace with actual preference
              onChanged: (value) {
                // Implement preference change
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}