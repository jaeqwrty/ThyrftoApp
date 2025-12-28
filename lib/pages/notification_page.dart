import 'package:flutter/material.dart';
import 'package:thryfto/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.righteous(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllNotificationsAsRead();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] ?? false;
              final createdAt = notification['created_at']?.toDate();

              return Dismissible(
                key: Key(notification['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _notificationService.deleteNotification(notification['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                },
                child: ListTile(
                  tileColor: isRead ? null : Colors.purple.withOpacity(0.05),
                  leading: CircleAvatar(
                    backgroundColor: _getNotificationColor(notification['type']),
                    child: Icon(
                      _getNotificationIcon(notification['type']),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notification['title'] ?? '',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification['body'] ?? ''),
                      if (createdAt != null)
                        Text(
                          timeago.format(createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: !isRead
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () async {
                    if (!isRead) {
                      await _notificationService.markNotificationAsRead(
                        notification['id'],
                      );
                    }
                    // Handle navigation based on notification type
                    _handleNotificationTap(notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'message':
        return Icons.message;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'share':
        return Colors.green;
      case 'message':
        return Colors.orange;
      case 'follow':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Implement navigation based on notification type
    // final type = notification['type'];
    // final relatedListingId = notification['related_listing_id'];
    // final relatedUserId = notification['related_user_id'];
  }
}