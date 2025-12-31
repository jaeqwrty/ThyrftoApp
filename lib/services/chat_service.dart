import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Upload chat image to Firebase Storage
  Future<String?> uploadChatImage({
    required XFile imageFile,
    required String chatId,
  }) async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        return null;
      }

      print('Starting image upload for chat: $chatId');

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(imageFile.name).isEmpty
          ? '.jpg'
          : path.extension(imageFile.name);
      final fileName = 'chat_${chatId}_${timestamp}$ext';

      print('Generated filename: $fileName');

      // Create storage reference
      final storageRef = _storage.ref().child('chats/$chatId/$fileName');
      print('Storage reference created: chats/$chatId/$fileName');

      // Read file bytes
      final bytes = await imageFile.readAsBytes();
      print('Image bytes read: ${bytes.length} bytes');

      // Upload file with metadata
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(
          contentType: _getContentType(imageFile.name),
          customMetadata: {
            'uploadedBy': currentUserId!,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      print('Upload complete, getting download URL...');

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('Image uploaded successfully: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Error uploading chat image:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      return null;
    } catch (e) {
      print('General Error uploading chat image: $e');
      return null;
    }
  }

  // Get content type based on file extension
  String _getContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // Delete chat image from storage
  Future<bool> deleteChatImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully: $imageUrl');
      return true;
    } catch (e) {
      print('Error deleting chat image: $e');
      return false;
    }
  }

  // Get or create chat
  Future<String?> getOrCreateChat(String otherUserId) async {
    if (currentUserId == null) return null;

    try {
      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new chat
      final chatRef = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return chatRef.id;
    } catch (e) {
      print('Error getting or creating chat: $e');
      return null;
    }
  }

  // Send message with notification - simplified version for conversation page
  Future<void> sendMessageWithNotification({
    required String recipientId,
    required String messageText,
  }) async {
    try {
      if (currentUserId == null) return;

      // Get current user's name for notification
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId!).get();
      final currentUserName = currentUserDoc.data()?['fullName'] ??
          currentUserDoc.data()?['full_name'] ??
          currentUserDoc.data()?['username'] ??
          'Someone';

      // Create notification
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
      // Don't throw - notification failure shouldn't block message sending
    }
  }

  // Send message with notification - full version with chatId
  Future<void> sendMessage({
    required String chatId,
    required String recipientId,
    required String messageText,
  }) async {
    try {
      if (currentUserId == null) return;

      // Get current user's name for notification
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId!).get();
      final currentUserName = currentUserDoc.data()?['fullName'] ??
          currentUserDoc.data()?['full_name'] ??
          currentUserDoc.data()?['username'] ??
          'Someone';

      // Send the message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      });

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Create notification
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
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send image message
  Future<void> sendImageMessage({
    required String chatId,
    required String recipientId,
    required String imageUrl,
  }) async {
    try {
      if (currentUserId == null) return;

      // Get current user's name for notification
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId!).get();
      final currentUserName = currentUserDoc.data()?['fullName'] ??
          currentUserDoc.data()?['full_name'] ??
          currentUserDoc.data()?['username'] ??
          'Someone';

      // Send the image message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'imageUrl': imageUrl,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'image',
      });

      // Update chat's last message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Create notification
      await _createNotification(
        recipientId: recipientId,
        type: 'message',
        title: 'New photo from $currentUserName',
        body: '📷 Sent a photo',
        relatedUserId: currentUserId,
      );
    } catch (e) {
      print('Error sending image message: $e');
      rethrow;
    }
  }

  // Get chat messages stream
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get user's chats stream
  Stream<QuerySnapshot> getUserChats() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots();
  }

  /// Delete a chat conversation and all its messages (including images)
  Future<bool> deleteChat(String chatId) async {
    try {
      // Get all messages to find and delete images
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      // Delete all images from storage
      for (var doc in messagesSnapshot.docs) {
        final messageData = doc.data();
        if (messageData['type'] == 'image' && messageData['imageUrl'] != null) {
          await deleteChatImage(messageData['imageUrl']);
        }
        // Delete message document
        await doc.reference.delete();
      }

      // Delete the chat document
      await _firestore.collection('chats').doc(chatId).delete();

      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }

  /// Delete a specific message from a chat (including image if present)
  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      // Get message data first
      final messageDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      if (messageDoc.exists) {
        final messageData = messageDoc.data();

        // Delete image from storage if it's an image message
        if (messageData?['type'] == 'image' &&
            messageData?['imageUrl'] != null) {
          await deleteChatImage(messageData!['imageUrl']);
        }
      }

      // Delete the message document
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Update last message if needed
      final remainingMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (remainingMessages.docs.isEmpty) {
        // No messages left, update chat
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      } else {
        // Update with the latest message
        final lastMsg = remainingMessages.docs.first.data();
        final lastMessageText =
            lastMsg['type'] == 'image' ? '📷 Photo' : lastMsg['text'] ?? '';

        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': lastMessageText,
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

  /// Internal helper: Create notification in Firestore with sender details
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
      // Get sender's information
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
      print('Notification created: $title');
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }
}
