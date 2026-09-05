import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/core/navigation/deep_link_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  static const Set<String> supportedTypes = {
    'like',
    'comment',
    'share',
    'message',
    'follow',
    'new_listing',
    'rating',
    'offer',
    'transaction',
  };

  /// Create a notification using one canonical client-side schema.
  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? relatedListingId,
    String? relatedUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    final senderId = currentUserId;
    if (senderId == null ||
        recipientId.isEmpty ||
        recipientId == senderId ||
        !supportedTypes.contains(type)) {
      return;
    }

    final normalizedTitle = title.trim();
    final normalizedBody = body.trim();
    if (normalizedTitle.isEmpty ||
        normalizedTitle.length > 160 ||
        normalizedBody.length > 1000) {
      return;
    }

    final normalizedAdditionalData = <String, dynamic>{
      ...?additionalData,
    };
    final deepLink = _buildDeepLink(
      type: type,
      relatedListingId: relatedListingId,
      additionalData: normalizedAdditionalData,
    );
    if (deepLink != null) {
      normalizedAdditionalData['deep_link'] = deepLink.toString();
    }

    try {
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      if (!senderDoc.exists) return;

      final senderData = senderDoc.data()!;
      final senderName = senderData['fullName'] ??
          senderData['full_name'] ??
          senderData['username'] ??
          'Someone';
      final senderProfileImage = senderData['profileImageUrl'] as String?;

      await _firestore.collection('notifications').add({
        'recipient_id': recipientId,
        'sender_id': senderId,
        'sender_name': senderName.toString(),
        'sender_profile_image': senderProfileImage,
        'type': type,
        'title': normalizedTitle,
        'body': normalizedBody,
        'related_listing_id': relatedListingId,
        'related_user_id': relatedUserId ?? senderId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'additional_data': normalizedAdditionalData,
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  Uri? _buildDeepLink({
    required String type,
    required String? relatedListingId,
    required Map<String, dynamic> additionalData,
  }) {
    switch (type) {
      case 'like':
      case 'comment':
      case 'share':
      case 'new_listing':
        final listingId = relatedListingId ??
            additionalData['listing_id']?.toString();
        if (listingId != null && listingId.isNotEmpty) {
          return DeepLinkService.listingUri(listingId);
        }
        return null;
      case 'message':
      case 'offer':
        final chatId = additionalData['chat_id']?.toString() ??
            additionalData['conversation_id']?.toString();
        if (chatId != null && chatId.isNotEmpty) {
          return DeepLinkService.chatUri(chatId);
        }
        return null;
      case 'transaction':
      case 'rating':
        final transactionId = additionalData['transaction_id']?.toString();
        if (transactionId != null && transactionId.isNotEmpty) {
          return DeepLinkService.transactionUri(transactionId);
        }
        return null;
      default:
        return null;
    }
  }

  /// Get all notifications for current user
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: currentUserId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .handleError((error) {
      print('Error getting notifications: $error');
      return [];
    }).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('recipient_id', isEqualTo: currentUserId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .handleError((error) {
      print('Error getting unread count: $error');
      return 0;
    }).map((snapshot) => snapshot.docs.length);
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (currentUserId == null) return;

    try {
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('recipient_id', isEqualTo: currentUserId)
          .where('is_read', isEqualTo: false)
          .get();

      // Use batch write to update all notifications at once
      // This prevents the countdown effect and updates the count to zero instantly
      if (unreadNotifications.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'is_read': true});
      }

      // Commit all updates in a single atomic operation
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Delete all notifications for current user
  Future<void> deleteAllNotifications() async {
    if (currentUserId == null) return;

    try {
      final userNotifications = await _firestore
          .collection('notifications')
          .where('recipient_id', isEqualTo: currentUserId)
          .get();

      for (var doc in userNotifications.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting all notifications: $e');
      rethrow;
    }
  }

  /// Get notification details by ID
  Future<Map<String, dynamic>?> getNotificationDetails(
      String notificationId) async {
    try {
      final doc = await _firestore
          .collection('notifications')
          .doc(notificationId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting notification details: $e');
      return null;
    }
  }
}
