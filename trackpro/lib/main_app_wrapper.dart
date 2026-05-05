import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/notification_provider.dart';
import 'widgets/notification_overlay.dart';

class MainAppWrapper extends StatelessWidget {
  final Widget child;
  final bool showNotificationOverlay;
  final bool showNotificationBadgeOnly;

  const MainAppWrapper({
    super.key,
    required this.child,
    this.showNotificationOverlay = true,
    this.showNotificationBadgeOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationWrapper(
      child: showNotificationOverlay
          ? NotificationOverlay(
              showBadgeOnly: showNotificationBadgeOnly,
              child: child,
            )
          : child,
    );
  }
}

// Example usage in main.dart:
// void main() {
//   runApp(
//     MainAppWrapper(
//       child: MaterialApp(
//         home: LoginScreen(),
//         // other app configuration
//       ),
//     ),
//   );
// }