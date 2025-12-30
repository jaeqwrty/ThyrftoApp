import 'package:flutter/material.dart';
import 'package:thryfto/services/notification_service.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllNotificationsAsRead();
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[100]),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: notifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72, // Aligns divider with the start of the text
              color: Colors.grey[50],
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] ?? false;
              final createdAt = notification['created_at']?.toDate();
              final senderProfileImage = notification['sender_profile_image'] as String?;

              return Dismissible(
                key: Key(notification['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red[400],
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _notificationService.deleteNotification(notification['id']);
                },
                child: InkWell(
                  onTap: () async {
                    if (!isRead) {
                      await _notificationService.markNotificationAsRead(notification['id']);
                    }
                    _handleNotificationTap(notification);
                  },
                  child: Container(
                    color: isRead ? Colors.transparent : const Color(0xFF8B5CF6).withOpacity(0.04),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Avatar with Unread Badge
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: _getNotificationColor(notification['type']).withOpacity(0.1),
                              backgroundImage: (senderProfileImage != null && senderProfileImage.isNotEmpty)
                                  ? NetworkImage(senderProfileImage)
                                  : null,
                              child: (senderProfileImage == null || senderProfileImage.isEmpty)
                                  ? Icon(
                                      _getNotificationIcon(notification['type']),
                                      color: _getNotificationColor(notification['type']),
                                      size: 18,
                                    )
                                  : null,
                            ),
                            if (!isRead)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Compact Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
                                  children: [
                                    TextSpan(
                                      text: "${notification['title'] ?? ''} ",
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: notification['body'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[200]),
          const SizedBox(height: 12),
          const Text('Error loading notifications'),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite;
      case 'comment': return Icons.comment;
      case 'reply': return Icons.reply;
      case 'share': return Icons.share;
      case 'message': return Icons.message;
      case 'follow': return Icons.person_add;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like': return Colors.red;
      case 'comment': return Colors.blue;
      case 'reply': return Colors.teal;
      case 'share': return Colors.green;
      case 'message': return Colors.orange;
      case 'follow': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Navigation logic goes here
    // Example: if (notification['type'] == 'message') { ... }
  }
}