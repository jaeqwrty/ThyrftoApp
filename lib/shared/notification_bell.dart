import 'package:flutter/material.dart';
import 'package:thryfto/services/notification_service.dart';

class NotificationBell extends StatelessWidget {
  final NotificationService notificationService;
  final VoidCallback onPressed;

  const NotificationBell({
    super.key,
    required this.notificationService,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationCount(),
      initialData: 0,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            // Bell icon button
            IconButton(
              icon: const Icon(Icons.notifications_none, size: 24),
              onPressed: onPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
            // Badge with unread count
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}