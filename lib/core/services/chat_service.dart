import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thryfto/core/services/cloudinary_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinary = CloudinaryService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Upload chat image to Cloudinary
  Future<String?> uploadChatImage({
    required XFile imageFile,
    required String chatId,
  }) async {
    try {
      if (currentUserId == null) return null;
      final url = await _cloudinary.uploadImage(
        imageFile,
        folder: 'chats/$chatId',
      );
      return url;
    } catch (e) {
      return null;
    }
  }

  // No-op: Cloudinary asset deletion is handled server-side / via dashboard.
  Future<bool> deleteChatImage(String imageUrl) async {
    return true;
  }

  /// Get the single conversation for a user pair, creating it when needed.
  Future<String?> getOrCreateChat(String otherUserId) async {
    final userId = currentUserId;
    if (userId == null || otherUserId.isEmpty || otherUserId == userId) {
      return null;
    }

    try {
      final canonicalChatId = _chatIdForUsers(userId, otherUserId);
      final existingChats = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      final matchingChats = existingChats.docs.where((doc) {
        final participants =
            List<String>.from(doc.data()['participants'] ?? const <String>[]);
        return participants.contains(otherUserId);
      }).toList();

      if (matchingChats.isNotEmpty) {
        // Prefer the canonical document when it already exists. For legacy random
        // IDs, prefer the most recently active thread and reuse it instead of
        // creating yet another conversation.
        matchingChats.sort((a, b) {
          if (a.id == canonicalChatId) return -1;
          if (b.id == canonicalChatId) return 1;
          final aTime = a.data()['lastMessageTime'] as Timestamp?;
          final bTime = b.data()['lastMessageTime'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        final chat = matchingChats.first;
        final deletedFor =
            List<String>.from(chat.data()['deletedFor'] ?? const <String>[]);

        if (deletedFor.contains(userId)) {
          // Reactivate the same thread. Keep the deletion timestamp so the
          // message list can continue hiding messages from before deletion.
          await chat.reference.update({
            'deletedFor': FieldValue.arrayRemove([userId]),
          });
        }

        return chat.id;
      }

      // Deterministic IDs make concurrent creation attempts converge on the
      // same document instead of producing duplicate conversations.
      final chatRef = _firestore.collection('chats').doc(canonicalChatId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(chatRef);
        if (!snapshot.exists) {
          transaction.set(chatRef, {
            'participants': [userId, otherUserId],
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'deletedFor': [],
            'deletedForTimestamps': {},
          });
        }
      });

      return chatRef.id;
    } catch (e) {
      print('Error getting/creating chat: $e');
      return null;
    }
  }

  String _chatIdForUsers(String firstUserId, String secondUserId) {
    final userIds = [firstUserId, secondUserId]..sort();
    return userIds.join('_');
  }

  /// Create a new chat (ONLY used internally - prefer getOrCreateChat)
  Future<String?> createChat(String otherUserId) async {
    if (currentUserId == null) return null;

    try {
      // Double-check if chat already exists before creating
      final existingChatId = await getOrCreateChat(otherUserId);
      return existingChatId;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  /// Soft delete - stores deletion timestamp to filter messages
  Future<bool> deleteChat(String chatId) async {
    try {
      if (currentUserId == null) return false;

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return false;

      final chatData = chatDoc.data()!;
      final participants = List<String>.from(chatData['participants']);
      final deletedFor = List<String>.from(chatData['deletedFor'] ?? []);

      // Check if current user already deleted it
      if (deletedFor.contains(currentUserId)) {
        return true; // Already deleted for this user
      }

      // Mark as deleted for current user with timestamp
      await _firestore.collection('chats').doc(chatId).update({
        'deletedFor': FieldValue.arrayUnion([currentUserId]),
        'deletedForTimestamps.$currentUserId': FieldValue.serverTimestamp(),
      });

      // Check if both users have now deleted it
      deletedFor.add(currentUserId!);

      if (deletedFor.length >= participants.length) {
        // Both users deleted it - permanently delete the chat and all messages
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .get();

        for (var messageDoc in messagesSnapshot.docs) {
          final messageData = messageDoc.data();

          // Delete image if it exists
          if (messageData['type'] == 'image' &&
              messageData['imageUrl'] != null) {
            await deleteChatImage(messageData['imageUrl']);
          }

          await messageDoc.reference.delete();
        }

        // Delete the chat document (now allowed by security rules when both users deleted)
        await _firestore.collection('chats').doc(chatId).delete();
      }

      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }

  Future<void> sendMessageWithNotification({
    required String recipientId,
    required String messageText,
  }) async {
    try {
      if (currentUserId == null) return;

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId!).get();
      final currentUserName = currentUserDoc.data()?['fullName'] ??
          currentUserDoc.data()?['full_name'] ??
          currentUserDoc.data()?['username'] ??
          'Someone';

      await _createNotification(
        recipientId: recipientId,
        type: 'message',
        title: 'New message from $currentUserName',
        body: messageText.length > 50
            ? '${messageText.substring(0, 50)}...'
            : messageText,
        relatedUserId: currentUserId,
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Stream<QuerySnapshot> getUserChats() {
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots();
  }

  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      final messageDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (messageDoc.exists) {
        final messageData = messageDoc.data();
        if (messageData?['type'] == 'image' &&
            messageData?['imageUrl'] != null) {
          await deleteChatImage(messageData!['imageUrl']);
        }
      }

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      final remainingMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (remainingMessages.docs.isEmpty) {
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      } else {
        final lastMsg = remainingMessages.docs.first.data();
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage':
              lastMsg['type'] == 'image' ? '📷 Photo' : lastMsg['text'] ?? '',
          'lastMessageTime':
              lastMsg['timestamp'] ?? FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  Future<void> _createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? relatedListingId,
    String? relatedUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String senderName = 'Someone';
      String? senderProfileImage;

      if (currentUserId != null) {
        final senderDoc =
            await _firestore.collection('users').doc(currentUserId).get();
        if (senderDoc.exists) {
          final senderData = senderDoc.data()!;
          senderName = senderData['fullName'] ??
              senderData['full_name'] ??
              senderData['username'] ??
              'Someone';
          senderProfileImage = senderData['profileImageUrl'] as String?;
        }
      }

      await _firestore.collection('notifications').add({
        'recipient_id': recipientId,
        'sender_id': currentUserId,
        'sender_name': senderName,
        'sender_profile_image': senderProfileImage,
        'type': type,
        'title': title,
        'body': body,
        'related_listing_id': relatedListingId,
        'related_user_id': relatedUserId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'additional_data': additionalData ?? {},
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }
}
