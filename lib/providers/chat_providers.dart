import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/services/chat_service.dart';
import 'package:thryfto/services/database_service.dart';

// Service providers
final chatServiceProvider = Provider((ref) => ChatService());
final databaseServiceProvider = Provider((ref) => DatabaseService());

// Chat list stream provider - gets all chats for current user
final chatListProvider =
    StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final currentUserId = chatService.currentUserId;

  if (currentUserId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

// Single chat stream provider
final chatProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  });
});

// Messages stream provider for a specific chat
final messagesProvider = StreamProvider.autoDispose
    .family<List<DocumentSnapshot>, String>((ref, chatId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

// Unread message count for a specific chat
final unreadCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  final currentUserId = chatService.currentUserId;

  if (currentUserId == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .where('senderId', isNotEqualTo: currentUserId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Total unread message count across all chats
final totalUnreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final currentUserId = chatService.currentUserId;

  if (currentUserId == null) {
    return Stream.value(0);
  }

  return FirebaseFirestore.instance
      .collection('chats')
      .where('participants', arrayContains: currentUserId)
      .snapshots()
      .asyncMap((chatsSnapshot) async {
    int totalUnread = 0;

    for (var chatDoc in chatsSnapshot.docs) {
      final chatData = chatDoc.data();
      final deletedFor = List<String>.from(chatData['deletedFor'] ?? []);

      // Skip if chat is deleted for current user
      if (deletedFor.contains(currentUserId)) continue;

      final unreadSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDoc.id)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      totalUnread += unreadSnapshot.docs.length;
    }

    return totalUnread;
  });
});

// StateNotifier for managing chat state (sending messages, etc.)
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  ChatNotifier(this._ref, this.chatId) : super(const AsyncValue.data(null));

  final Ref _ref;
  final String chatId;

  Future<void> sendTextMessage(String text, String otherUserId) async {
    if (text.trim().isEmpty) return;

    state = const AsyncValue.loading();

    try {
      final chatService = _ref.read(chatServiceProvider);
      final currentUserId = chatService.currentUserId;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final batch = FirebaseFirestore.instance.batch();

      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      });

      batch.update(FirebaseFirestore.instance.collection('chats').doc(chatId), {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Send notification
      await chatService.sendMessageWithNotification(
        recipientId: otherUserId,
        messageText: text,
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> sendImageMessage(imageFile, String otherUserId) async {
    state = const AsyncValue.loading();

    try {
      final chatService = _ref.read(chatServiceProvider);
      final currentUserId = chatService.currentUserId;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Upload image first
      final imageUrl = await chatService.uploadChatImage(
        imageFile: imageFile,
        chatId: chatId,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }

      final batch = FirebaseFirestore.instance.batch();

      final messageRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      batch.set(messageRef, {
        'senderId': currentUserId,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'image',
      });

      batch.update(FirebaseFirestore.instance.collection('chats').doc(chatId), {
        'lastMessage': '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Send notification
      await chatService.sendMessageWithNotification(
        recipientId: otherUserId,
        messageText: '📷 Sent a photo',
      );

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markMessagesAsRead() async {
    try {
      final chatService = _ref.read(chatServiceProvider);
      final currentUserId = chatService.currentUserId;

      if (currentUserId == null) return;

      final unreadMessages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}

// Provider for chat notifier
final chatNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, AsyncValue<void>, String>((ref, chatId) {
  return ChatNotifier(ref, chatId);
});
