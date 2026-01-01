import 'package:flutter/material.dart';
import 'package:thryfto/global/app_colors.dart';
import 'package:thryfto/services/notification_service.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllNotificationsAsRead();
            },
            child: Text(
              'Mark all read',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
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

          final groupedNotifications = _groupNotifications(notifications);

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: groupedNotifications.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 72,
              color: AppColors.backgroundGrey,
            ),
            itemBuilder: (context, index) {
              final group = groupedNotifications[index];
              final isGrouped = group['unique_count'] > 1;
              final hasUnread = group['has_unread'] as bool;

              return Dismissible(
                key: Key(group['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppColors.errorLight,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete_outline, color: AppColors.textWhite),
                ),
                onDismissed: (direction) {
                  for (var notif in group['notifications'] as List) {
                    _notificationService.deleteNotification(notif['id']);
                  }
                },
                child: InkWell(
                  onTap: () async {
                    if (hasUnread) {
                      for (var notif in group['notifications'] as List) {
                        if (!(notif['is_read'] ?? false)) {
                          await _notificationService.markNotificationAsRead(notif['id']);
                        }
                      }
                    }
                    _handleNotificationTap(group);
                  },
                  child: Container(
                    color: hasUnread 
                        ? AppColors.primaryBackgroundLight
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: isGrouped 
                        ? _buildGroupedNotification(group, hasUnread)
                        : _buildSingleNotification(group, hasUnread),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupNotifications(List<Map<String, dynamic>> notifications) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    
    for (var notification in notifications) {
      final type = notification['type'];
      
      if (type == 'message') {
        final key = '${notification['id']}_single';
        groups[key] = [notification];
        continue;
      }

      String groupKey;
      if (type == 'rating') {
        groupKey = 'rating_${notification['recipient_id']}';
      } else if (type == 'follow' || type == 'favorite') {
        groupKey = 'follow_${notification['recipient_id']}';
      } else if (type == 'new_listing') {
        final listingId = notification['additional_data']?['listing_id'];
        groupKey = 'new_listing_${listingId ?? 'unknown'}';
      } else {
        groupKey = '${type}_${notification['recipient_id']}';
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(notification);
    }

    final List<Map<String, dynamic>> result = [];
    groups.forEach((key, notificationList) {
      notificationList.sort((a, b) {
        final aTime = a['created_at']?.toDate() ?? DateTime.now();
        final bTime = b['created_at']?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      final uniqueUserIds = <String>{};
      for (var notif in notificationList) {
        final userId = notif['related_user_id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          uniqueUserIds.add(userId);
        }
      }

      final mostRecent = notificationList.first;
      final hasUnread = notificationList.any((n) => !(n['is_read'] ?? false));

      result.add({
        'id': key,
        'type': mostRecent['type'],
        'count': notificationList.length,
        'unique_count': uniqueUserIds.length,
        'unique_user_ids': uniqueUserIds.toList(),
        'notifications': notificationList,
        'most_recent': mostRecent,
        'has_unread': hasUnread,
        'created_at': mostRecent['created_at'],
      });
    });

    result.sort((a, b) {
      final aTime = a['created_at']?.toDate() ?? DateTime.now();
      final bTime = b['created_at']?.toDate() ?? DateTime.now();
      return bTime.compareTo(aTime);
    });

    return result;
  }

  Widget _buildGroupedNotification(Map<String, dynamic> group, bool hasUnread) {
    final uniqueCount = group['unique_count'] as int;
    final type = group['type'] as String;
    final uniqueUserIds = group['unique_user_ids'] as List<dynamic>;
    final mostRecent = group['most_recent'] as Map<String, dynamic>;
    final createdAt = mostRecent['created_at']?.toDate();

    final displayUserIds = uniqueUserIds.take(3).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            children: [
              if (displayUserIds.isNotEmpty) ...[
                Positioned(
                  left: 0,
                  top: 0,
                  child: _buildAvatar(displayUserIds[0].toString(), 32, hasUnread, type),
                ),
                if (displayUserIds.length > 1)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.backgroundWhite, width: 2),
                      ),
                      child: _buildAvatar(displayUserIds[1].toString(), 24, false, type),
                    ),
                  ),
              ] else
                _buildDefaultAvatar(type, hasUnread),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3),
                  children: [
                    TextSpan(
                      text: _getGroupedTitle(type, uniqueCount, group),
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
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
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleNotification(Map<String, dynamic> group, bool hasUnread) {
    final notification = group['most_recent'] as Map<String, dynamic>;
    final createdAt = notification['created_at']?.toDate();
    final senderProfileImage = notification['sender_profile_image'] as String?;
    final relatedUserId = notification['related_user_id'] as String?;
    final type = notification['type'] as String;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            if (relatedUserId != null)
              _buildAvatar(relatedUserId, 40, hasUnread, type)
            else
              _buildStaticAvatar(senderProfileImage, type, hasUnread),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.backgroundWhite, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3),
                  children: [
                    TextSpan(
                      text: "${notification['title'] ?? ''} ",
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: notification['body'] ?? '',
                      style: TextStyle(
                        color: AppColors.textSecondary,
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
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String userId, double size, bool hasUnread, String type) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _db.getUserProfileStream(userId),
      builder: (context, snapshot) {
        final profileImageUrl = snapshot.data?['profileImageUrl'] as String?;
        final fullName = snapshot.data?['fullName'] as String? ?? 
                        snapshot.data?['full_name'] as String? ?? 'U';

        return CircleAvatar(
          radius: size / 2,
          backgroundColor: _getNotificationColor(type).withOpacity(0.1),
          backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
              ? NetworkImage(profileImageUrl)
              : null,
          child: (profileImageUrl == null || profileImageUrl.isEmpty)
              ? Text(
                  fullName[0].toUpperCase(),
                  style: TextStyle(
                    color: _getNotificationColor(type),
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildStaticAvatar(String? profileImage, String type, bool hasUnread) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getNotificationColor(type).withOpacity(0.1),
      backgroundImage: (profileImage != null && profileImage.isNotEmpty)
          ? NetworkImage(profileImage)
          : null,
      child: (profileImage == null || profileImage.isEmpty)
          ? Icon(
              _getNotificationIcon(type),
              color: _getNotificationColor(type),
              size: 18,
            )
          : null,
    );
  }

  Widget _buildDefaultAvatar(String type, bool hasUnread) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getNotificationColor(type).withOpacity(0.1),
      child: Icon(
        _getNotificationIcon(type),
        color: _getNotificationColor(type),
        size: 18,
      ),
    );
  }

  String _getGroupedTitle(String type, int uniqueCount, Map<String, dynamic> group) {
    if (uniqueCount == 1) {
      final notifications = group['notifications'] as List<Map<String, dynamic>>;
      final notif = notifications.first;
      return "${notif['title'] ?? ''} ${notif['body'] ?? ''}";
    }

    final notifications = group['notifications'] as List<Map<String, dynamic>>;
    String firstName = 'Someone';
    final firstNotif = notifications.first;
    final body = firstNotif['body']?.toString() ?? '';
    
    if (body.isNotEmpty) {
      final words = body.split(' ');
      if (words.isNotEmpty) {
        firstName = words[0];
      }
    }
    
    if (firstName == 'Someone') {
      final title = firstNotif['title']?.toString() ?? '';
      if (title.isNotEmpty) {
        firstName = title.split(' ').first;
      }
    }

    final othersCount = uniqueCount - 1;

    switch (type) {
      case 'rating':
        return othersCount == 1
            ? "$firstName and 1 other rated you"
            : "$firstName and $othersCount others rated you";
      case 'follow':
      case 'favorite':
        return othersCount == 1
            ? "$firstName and 1 other started following you"
            : "$firstName and $othersCount others started following you";
      case 'new_listing':
        return othersCount == 1
            ? "$firstName posted 2 new listings"
            : "$firstName posted ${uniqueCount} new listings";
      default:
        return othersCount == 1
            ? "$firstName and 1 other interacted with you"
            : "$firstName and $othersCount others interacted with you";
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 48, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 15, color: AppColors.textTertiary),
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
          Icon(Icons.error_outline, size: 48, color: AppColors.errorLight),
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
      case 'favorite': return Icons.notifications_active;
      case 'new_listing': return Icons.shopping_bag;
      case 'rating': return Icons.star;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like': return AppColors.like;
      case 'comment': return AppColors.info;
      case 'reply': return Colors.teal;
      case 'share': return AppColors.success;
      case 'message': return AppColors.warning;
      case 'follow': return AppColors.primary;
      case 'favorite': return AppColors.primary;
      case 'new_listing': return AppColors.success;
      case 'rating': return AppColors.rating;
      default: return AppColors.textSecondary;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> group) {
    final type = group['type'];
    final notifications = group['notifications'] as List<Map<String, dynamic>>;
    
    print('Notification group tapped: $type with ${notifications.length} items');
  }
}