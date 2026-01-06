import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/services/notification_service.dart';

// Notification service provider
final notificationServiceProvider = Provider((ref) => NotificationService());

// User notifications stream provider with null safety
final userNotificationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUserNotifications();
});

// Unread notification count provider with null safety
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUnreadNotificationCount();
});

// Grouped notifications provider
final groupedNotificationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final notificationsAsync = ref.watch(userNotificationsProvider);
  
  return notificationsAsync.when(
    data: (notifications) => _groupNotifications(notifications),
    error: (_, __) => [],
    loading: () => [],
  );
});

List<Map<String, dynamic>> _groupNotifications(List<Map<String, dynamic>> notifications) {
  final Map<String, List<Map<String, dynamic>>> groups = {};
  
  for (var notification in notifications) {
    final type = notification['type'];
    final senderId = notification['sender_id'] as String?;
    final relatedListingId = notification['related_listing_id'] as String?;

    String groupKey;
    if (type == 'message') {
      // Group messages by sender
      groupKey = 'message_${senderId ?? 'unknown'}';
    } else if (type == 'comment' || type == 'reply') {
      // Group comments by listing
      groupKey = 'comment_${relatedListingId ?? 'unknown'}';
    } else if (type == 'rating') {
      groupKey = 'rating_${notification['recipient_id']}';
    } else if (type == 'follow' || type == 'favorite') {
      groupKey = 'follow_${notification['recipient_id']}';
    } else if (type == 'new_listing') {
      final listingId = notification['additional_data']?['listing_id'];
      groupKey = 'new_listing_${listingId ?? 'unknown'}';
    } else if (type == 'like') {
      // Group likes by listing
      groupKey = 'like_${relatedListingId ?? 'unknown'}';
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
      final aCreatedAt = a['created_at'];
      final bCreatedAt = b['created_at'];
      final aTime = aCreatedAt != null ? aCreatedAt.toDate() : DateTime.now();
      final bTime = bCreatedAt != null ? bCreatedAt.toDate() : DateTime.now();
      return bTime.compareTo(aTime);
    });

    final mostRecent = notificationList.first;
    final hasUnread = notificationList.any((n) => !(n['is_read'] ?? false));
    
    // For messages, each sender gets their own group (no aggregation)
    final type = mostRecent['type'];
    final uniqueUserIds = <String>{};
    
    for (var notif in notificationList) {
      if (type == 'message') {
        // For messages, only use sender_id
        final userId = notif['sender_id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          uniqueUserIds.add(userId);
        }
      } else {
        // For other types, use sender_id or related_user_id
        final userId = notif['sender_id'] as String? ?? notif['related_user_id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          uniqueUserIds.add(userId);
        }
      }
    }

    result.add({
      'id': key,
      'type': type,
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
    final aCreatedAt = a['created_at'];
    final bCreatedAt = b['created_at'];
    final aTime = aCreatedAt != null ? aCreatedAt.toDate() : DateTime.now();
    final bTime = bCreatedAt != null ? bCreatedAt.toDate() : DateTime.now();
    return bTime.compareTo(aTime);
  });

  return result;
}
