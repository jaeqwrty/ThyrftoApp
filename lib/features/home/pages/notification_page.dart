import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:thryfto/core/navigation/deep_link_router.dart';
import 'package:thryfto/core/navigation/deep_link_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/providers/notification_providers.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';
import 'package:thryfto/features/profile/pages/user_profile_page.dart';
import 'package:thryfto/shared/widgets/comments_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:thryfto/shared/widgets/skeleton_loaders.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final DatabaseService _db = DatabaseService();
  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _page = Color(0xFFF6F3F8);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _accent = Color(0xFFA8752A);

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final notificationService = ref.watch(notificationServiceProvider);

    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await notificationService.markAllNotificationsAsRead();
            },
            child: Text(
              'Mark all read',
              style: const TextStyle(
                color: _ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: _line),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          final groupedNotifications = _groupNotifications(notifications);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
            itemCount: groupedNotifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                    notificationService.deleteNotification(notif['id']);
                  }
                },
                child: InkWell(
                  onTap: () async {
                    if (hasUnread) {
                      for (var notif in group['notifications'] as List) {
                        if (!(notif['is_read'] ?? false)) {
                          await notificationService.markNotificationAsRead(notif['id']);
                        }
                      }
                    }
                    _handleNotificationTap(group);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasUnread ? _accent.withValues(alpha: 0.45) : _line,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ink.withValues(alpha: 0.035),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: isGrouped 
                        ? _buildGroupedNotification(group, hasUnread)
                        : _buildSingleNotification(group, hasUnread),
                  ),
                ),
              );
            },
          );
        },
        error: (error, stackTrace) => _buildErrorState(),
        loading: () => const NotificationListSkeleton(),
      ),
    );
  }

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
        final ratingId = notification['additional_data']?['rating_id'];
        groupKey = 'rating_${ratingId ?? 'unknown'}';
      } else if (type == 'follow' || type == 'favorite') {
        groupKey = 'follow_${notification['recipient_id']}';
      } else if (type == 'new_listing') {
        final listingId = notification['additional_data']?['listing_id'];
        groupKey = 'new_listing_${listingId ?? 'unknown'}';
      } else if (type == 'like') {
        // Group likes by listing
        groupKey = 'like_${relatedListingId ?? 'unknown'}';
      } else if (type == 'offer') {
        final offerId = notification['additional_data']?['offer_id'];
        final offerStatus = notification['additional_data']?['offer_status'];
        groupKey = 'offer_${offerId ?? 'unknown'}_${offerStatus ?? 'update'}';
      } else if (type == 'transaction') {
        final transactionId =
            notification['additional_data']?['transaction_id'];
        final transactionStatus =
            notification['additional_data']?['transaction_status'];
        groupKey =
            'transaction_${transactionId ?? 'unknown'}_${transactionStatus ?? 'update'}';
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
        final userId = notif['sender_id'] as String? ?? notif['related_user_id'] as String?;
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
                        border: Border.all(color: Colors.white, width: 2),
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
                  style: const TextStyle(fontSize: 14, color: _ink, height: 1.3),
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
                    color: _muted,
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
                    color: _accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
                  style: const TextStyle(fontSize: 14, color: _ink, height: 1.3),
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
                        color: _muted,
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
                    color: _muted,
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
          backgroundColor: _getNotificationColor(type).withValues(alpha: 0.1),
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
      backgroundColor: _getNotificationColor(type).withValues(alpha: 0.1),
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
      backgroundColor: _getNotificationColor(type).withValues(alpha: 0.1),
      child: Icon(
        _getNotificationIcon(type),
        color: _getNotificationColor(type),
        size: 18,
      ),
    );
  }

  String _getGroupedTitle(String type, int uniqueCount, Map<String, dynamic> group) {
    final notifications = group['notifications'] as List<Map<String, dynamic>>;
    final count = notifications.length;
    
    if (uniqueCount == 1) {
      final notif = notifications.first;
      
      // For messages, show message count if multiple
      if (type == 'message' && count > 1) {
        final senderName = notif['title']?.toString().replaceAll(' sent you a message', '') ?? 'Someone';
        return '$senderName sent you $count messages';
      }
      
      // For comments, show comment count if multiple
      if (type == 'comment' && count > 1) {
        final commenterName = notif['title']?.toString().split(' ').first ?? 'Someone';
        return '$commenterName left $count comments on your listing';
      }
      
      // For likes on same listing, show like count
      if (type == 'like' && count > 1) {
        final likerName = notif['title']?.toString().split(' ').first ?? 'Someone';
        return '$likerName and ${count - 1} others liked your listing';
      }
      
      return "${notif['title'] ?? ''} ${notif['body'] ?? ''}";
    }

    final firstNotif = notifications.first;
    String firstName = 'Someone';
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
      case 'message':
        return othersCount == 1
            ? "$firstName and 1 other sent you messages"
            : "$firstName and $othersCount others sent you messages";
      case 'comment':
      case 'reply':
        return othersCount == 1
            ? "$firstName and 1 other commented on your listing"
            : "$firstName and $othersCount others commented on your listing";
      case 'like':
        return othersCount == 1
            ? "$firstName and 1 other liked your listing"
            : "$firstName and $othersCount others liked your listing";
      case 'rating':
        return othersCount == 1
            ? "$firstName and 1 other left verified reviews"
            : "$firstName and $othersCount others left verified reviews";
      case 'offer':
        return othersCount == 1
            ? "$firstName and 1 other updated offers"
            : "$firstName and $othersCount others updated offers";
      case 'transaction':
        return othersCount == 1
            ? "$firstName and 1 other updated transactions"
            : "$firstName and $othersCount others updated transactions";
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
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _line),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 32,
              color: _muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: const TextStyle(
              fontSize: 15,
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
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
      case 'offer': return Icons.local_offer_outlined;
      case 'transaction': return Icons.handshake_outlined;
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
      case 'follow': return _ink;
      case 'favorite': return _ink;
      case 'new_listing': return AppColors.success;
      case 'rating': return AppColors.rating;
      case 'offer': return _accent;
      case 'transaction': return AppColors.success;
      default: return AppColors.textSecondary;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> group) async {
    final type = group['type'];
    final mostRecent = group['most_recent'] as Map<String, dynamic>;
    final relatedListingId = mostRecent['related_listing_id'] as String?;
    final relatedUserId = mostRecent['related_user_id'] as String?;
    final senderId = mostRecent['sender_id'] as String?;
    final additionalData = mostRecent['additional_data'] as Map<String, dynamic>?;

    // Derive the authoritative target from source metadata first. Persisted
    // deep_link values are accepted only when they point to the same target.
    Uri? deepLink;
    switch (type) {
      case 'like':
      case 'comment':
      case 'reply':
      case 'share':
        if (relatedListingId != null && relatedListingId.isNotEmpty) {
          deepLink = DeepLinkService.listingUri(relatedListingId);
        }
        break;
      case 'new_listing':
        final listingId = relatedListingId ??
            additionalData?['listing_id']?.toString();
        if (listingId != null && listingId.isNotEmpty) {
          deepLink = DeepLinkService.listingUri(listingId);
        }
        break;
      case 'message':
      case 'offer':
        final chatId = additionalData?['chat_id']?.toString() ??
            additionalData?['conversation_id']?.toString();
        if (chatId != null && chatId.isNotEmpty) {
          deepLink = DeepLinkService.chatUri(chatId);
        }
        break;
      case 'transaction':
      case 'rating':
        final transactionId = additionalData?['transaction_id']?.toString();
        if (transactionId != null && transactionId.isNotEmpty) {
          deepLink = DeepLinkService.transactionUri(transactionId);
        }
        break;
    }

    final storedDeepLink = additionalData?['deep_link']?.toString();
    if (deepLink != null &&
        storedDeepLink != null &&
        storedDeepLink.isNotEmpty) {
      final storedUri = Uri.tryParse(storedDeepLink);
      final expectedTarget = DeepLinkTarget.parse(deepLink);
      final storedTarget = storedUri == null ? null : DeepLinkTarget.parse(storedUri);
      if (expectedTarget != null &&
          storedTarget != null &&
          expectedTarget.kind == storedTarget.kind &&
          expectedTarget.id == storedTarget.id) {
        deepLink = storedUri;
      }
    }

    if (deepLink != null && mounted) {
      final currentUser = await _getCurrentUser();
      if (!mounted) return;
      final handled = await DeepLinkRouter.open(
        context,
        deepLink,
        currentUser: currentUser,
      );
      if (handled) return;
    }
    
    try {
      switch (type) {
        case 'like':
          // Navigate to listing detail page
          if (relatedListingId != null) {
            final listing = await _db.getListingById(relatedListingId);
            if (listing != null && mounted) {
              final currentUser = await _getCurrentUser();
              Navigator.push(
                context,
                AppPageRoute.fadeThrough(
                  builder: (context) => ListingDetailPage(
                    listing: listing,
                    user: currentUser,
                  ),
                ),
              );
            }
          }
          break;
          
        case 'comment':
        case 'reply':
          // Navigate to comments modal for the listing
          if (relatedListingId != null && mounted) {
            final currentUser = await _getCurrentUser();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CommentsModal(
                listingId: relatedListingId,
                user: currentUser,
              ),
            );
          }
          break;
          
        case 'message':
        case 'offer':
        case 'transaction':
          // Open the conversation associated with the interaction.
          if (senderId != null && mounted) {
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            if (currentUserId != null) {
              final conversationId = additionalData?['chat_id'] as String? ??
                  additionalData?['conversation_id'] as String?;
              final currentUser = await _getCurrentUser();
              final otherUser = await _db.getUserProfile(senderId);
              
              if (otherUser != null) {
                Navigator.push(
                  context,
                  AppPageRoute.fadeThrough(
                    builder: (context) => ConversationPage(
                      chatId: conversationId,
                      otherUserId: senderId,
                      otherUserName: otherUser['username'] ?? otherUser['fullName'] ?? 'User',
                      currentUser: currentUser,
                    ),
                  ),
                );
              }
            }
          }
          break;
          
        case 'follow':
        case 'favorite':
          // Navigate to user profile
          if (relatedUserId != null && mounted) {
            final currentUser = await _getCurrentUser();
            Navigator.push(
              context,
              AppPageRoute.fadeThrough(
                builder: (context) => UserProfilePage(
                  userId: relatedUserId,
                  currentUser: currentUser,
                ),
              ),
            );
          }
          break;
          
        case 'new_listing':
          // Navigate to listing detail page
          final listingId = additionalData?['listing_id'] as String?;
          if (listingId != null) {
            final listing = await _db.getListingById(listingId);
            if (listing != null && mounted) {
              final currentUser = await _getCurrentUser();
              Navigator.push(
                context,
                AppPageRoute.fadeThrough(
                  builder: (context) => ListingDetailPage(
                    listing: listing,
                    user: currentUser,
                  ),
                ),
              );
            }
          }
          break;
          
        case 'share':
          // Navigate to listing detail page
          if (relatedListingId != null) {
            final listing = await _db.getListingById(relatedListingId);
            if (listing != null && mounted) {
              final currentUser = await _getCurrentUser();
              Navigator.push(
                context,
                AppPageRoute.fadeThrough(
                  builder: (context) => ListingDetailPage(
                    listing: listing,
                    user: currentUser,
                  ),
                ),
              );
            }
          }
          break;
          
        case 'rating':
          // Could navigate to ratings/reviews section if you have one
          // For now, navigate to user profile
          if (relatedUserId != null && mounted) {
            final currentUser = await _getCurrentUser();
            Navigator.push(
              context,
              AppPageRoute.fadeThrough(
                builder: (context) => UserProfilePage(
                  userId: relatedUserId,
                  currentUser: currentUser,
                ),
              ),
            );
          }
          break;
          
        default:
          print('Unknown notification type: $type');
      }
    } catch (e) {
      print('Error handling notification tap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open notification'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<Map<String, dynamic>> _getCurrentUser() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      final userData = await _db.getUserProfile(currentUserId);
      return userData ?? {'id': currentUserId};
    }
    return {};
  }
}
