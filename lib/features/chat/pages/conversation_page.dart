import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/core/utils/common_dialogs.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:thryfto/features/chat/widgets/messages_input.dart';
import 'package:thryfto/features/chat/widgets/message_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/providers/chat_providers.dart';

class ConversationPage extends ConsumerStatefulWidget {
  final String? chatId;
  final String otherUserId;
  final String otherUserName;
  final Map<String, dynamic> currentUser;

  const ConversationPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.currentUser,
  });

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();

  bool _hasMarkedAsRead = false;
  String? _activeChatId;
  bool _isInitialized = false;

  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _page = Color(0xFFF6F3F8);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _accent = Color(0xFFA8752A);

  // Use ValueNotifier to prevent full widget rebuilds
  final ValueNotifier<bool> _isUploadingImage = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _isInitialized = true;
    // If no chatId provided, get or create it immediately
    if (widget.chatId == null) {
      _ensureChatExists().then((chatId) {
        if (mounted && chatId != null) {
          setState(() {
            _activeChatId = chatId;
          });
        }
      });
    } else {
      _activeChatId = widget.chatId;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _isUploadingImage.dispose();
    super.dispose();
  }

  Future<String?> _ensureChatExists() async {
    if (_activeChatId != null) return _activeChatId;

    try {
      // Use Riverpod provider to get or create chat
      final chatService = ref.read(chatServiceProvider);
      final chatId = await chatService.getOrCreateChat(widget.otherUserId);
      if (chatId != null && _isInitialized && mounted) {
        setState(() {
          _activeChatId = chatId;
        });
      }
      return chatId;
    } catch (_) {
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Clear immediately for better UX
    _messageController.clear();

    try {
      final chatId = await _ensureChatExists();
      if (chatId == null) throw Exception('Failed to create chat');

      // Use Riverpod provider instead of manual batch operations
      await ref.read(chatNotifierProvider(chatId).notifier).sendTextMessage(
            text,
            widget.otherUserId,
          );
    } catch (_) {
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //         content: Text('Failed to send message'),
      //         backgroundColor: Colors.red),
      //   );
      // }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;
      if (!mounted) return;

      _showImagePreviewDialog(image);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to pick image'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showImagePreviewDialog(XFile image) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: _line)),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, color: _ink),
                    const SizedBox(width: 12),
                    const Text(
                      'Send Image',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _ink),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ClipRRect(
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _sendImageMessage(image);
                        },
                        icon: const Icon(Icons.send, size: 20),
                        label: const Text('Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _ink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendImageMessage(XFile image) async {
    if (!mounted) return;
    _isUploadingImage.value = true;

    try {
      final chatId = await _ensureChatExists();
      if (chatId == null) throw Exception('Failed to create chat');

      // Use Riverpod provider instead of manual batch operations
      await ref.read(chatNotifierProvider(chatId).notifier).sendImageMessage(
            image,
            widget.otherUserId,
          );
    } catch (_) {
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //         content: const Text('Failed to send image'),
      //         backgroundColor: Colors.red),
      //   );
      // }
    } finally {
      if (mounted) _isUploadingImage.value = false;
    }
  }

  void _showImageSourceDialog() {
    CommonModals.showOptionsModal(
      context,
      title: 'Send Photo',
      items: [
        OptionsModalItem(
          icon: Icons.camera_alt,
          iconColor: _ink,
          iconBackgroundColor: _ink,
          title: 'Take Photo',
          onTap: () => _pickImage(ImageSource.camera),
        ),
        OptionsModalItem(
          icon: Icons.photo_library,
          iconColor: _ink,
          iconBackgroundColor: _ink,
          title: 'Choose from Gallery',
          onTap: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Future<void> _markMessagesAsRead() async {
    if (_hasMarkedAsRead || _activeChatId == null) return;

    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(_activeChatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _db.currentUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      _hasMarkedAsRead = true;
    } catch (_) {
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    if (_activeChatId == null) return;

    final confirm = await _showFloatingDeleteDialog(
      title: 'Delete Message',
      message: 'Are you sure you want to delete this message?',
      icon: Icons.chat_bubble_outline,
    );

    if (confirm != true) return;

    try {
      await _firestore
          .collection('chats')
          .doc(_activeChatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      final remainingMessages = await _firestore
          .collection('chats')
          .doc(_activeChatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (remainingMessages.docs.isEmpty) {
        // Soft delete the chat instead of hard deleting
        final userId = ref.read(authServiceProvider).currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('chats').doc(_activeChatId).update({
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'deletedFor': FieldValue.arrayUnion([userId]),
            'deletedForTimestamps.$userId': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Conversation deleted - no messages left'),
              backgroundColor: _ink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        final lastMsg = remainingMessages.docs.first.data();
        await _firestore.collection('chats').doc(_activeChatId).update({
          'lastMessage':
              lastMsg['type'] == 'image' ? '📷 Photo' : lastMsg['text'] ?? '',
          'lastMessageTime':
              lastMsg['timestamp'] ?? FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Message deleted'),
              backgroundColor: _ink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete message'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _deleteEntireChat() async {
    if (_activeChatId == null) return;

    final confirm = await _showFloatingDeleteDialog(
      title: 'Delete Conversation',
      message:
          'Delete this conversation for yourself? ${widget.otherUserName} will still have it.',
      icon: Icons.forum_outlined,
    );

    if (confirm != true) return;

    try {
      // Use Riverpod provider instead of service instance
      final chatService = ref.read(chatServiceProvider);
      final success = await chatService.deleteChat(_activeChatId!);

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Conversation deleted'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete conversation'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool?> _showFloatingDeleteDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatOptions() {
    CommonModals.showOptionsModal(
      context,
      title: 'Conversation Options',
      items: [
        OptionsModalItem.delete(
          title: 'Delete Entire Conversation',
          subtitle: 'This action cannot be undone',
          onTap: _deleteEntireChat,
        ),
      ],
    );
  }

  void _showImagePreview(String imageUrl) {
    CommonDialogs.showImagePreviewDialog(context, imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: _line)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: StreamBuilder<Map<String, dynamic>?>(
          stream: _db.getUserProfileStream(widget.otherUserId),
          builder: (context, snapshot) {
            final otherUser = snapshot.data;
            final fullName = otherUser?['fullName'] ?? otherUser?['full_name'];
            final username = otherUser?['username'];
            final displayName = fullName ?? username ?? widget.otherUserName;
            final profileImageUrl = otherUser?['profileImageUrl'] as String?;

            String locationText = 'Location not set';
            bool hasLocation = false;

            if (otherUser != null) {
              if (otherUser['latitude'] != null &&
                  otherUser['longitude'] != null &&
                  otherUser['address'] != null &&
                  otherUser['address'].toString().isNotEmpty) {
                locationText = otherUser['address'];
                hasLocation = true;
              } else if (otherUser['cityState'] != null &&
                  otherUser['cityState'].toString().isNotEmpty) {
                locationText = otherUser['cityState'];
                hasLocation = true;
              } else if (otherUser['location'] != null) {
                final location = otherUser['location'] as Map<String, dynamic>;
                if (location['latitude'] != null &&
                    location['longitude'] != null &&
                    location['address'] != null &&
                    location['address'].toString().isNotEmpty) {
                  locationText = location['address'];
                  hasLocation = true;
                }
              }
            }

            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent.withValues(alpha: 0.45)),
                  ),
                  child: CircleAvatar(
                    backgroundColor: _surface,
                    backgroundImage:
                        (profileImageUrl != null && profileImageUrl.isNotEmpty)
                            ? NetworkImage(profileImageUrl)
                            : null,
                    child: (profileImageUrl == null || profileImageUrl.isEmpty)
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: hasLocation ? _muted : Color(0xFFAAA3B5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationText,
                              style: TextStyle(
                                color:
                                    hasLocation ? _muted : Color(0xFFAAA3B5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontStyle: hasLocation
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          if (_activeChatId != null)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: _ink),
              onPressed: _showChatOptions,
              style: IconButton.styleFrom(
                backgroundColor: _surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: _line),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _activeChatId != null
                ? MessagesList(
                    chatId: _activeChatId!,
                    currentUserId: _db.currentUserId ?? '',
                    scrollController: _scrollController,
                    onMarkMessagesAsRead: _markMessagesAsRead,
                    onDeleteMessage: _deleteMessage,
                    onImageTap: _showImagePreview,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
          ),
          // Use ValueListenableBuilder instead of setState
          ValueListenableBuilder<bool>(
            valueListenable: _isUploadingImage,
            builder: (context, isUploading, child) {
              if (!isUploading) return const SizedBox.shrink();

              return Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Uploading image...',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          MessageInput(
            controller: _messageController,
            onSendMessage: _sendMessage,
            onAttachImage: _showImageSourceDialog,
          ),
        ],
      ),
    );
  }
}
