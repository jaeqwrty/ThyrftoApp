import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/global/app_colors.dart';
import 'package:thryfto/services/chat_service.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:thryfto/chatWidgets/messages_input.dart';
import 'package:thryfto/chatWidgets/message_list.dart';

class ConversationPage extends StatefulWidget {
  final String chatId;
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
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  bool _hasMarkedAsRead = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'senderId': _db.currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      await _chatService.sendMessageWithNotification(
        recipientId: widget.otherUserId,
        messageText: text,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            'Failed to Send', 'Could not send your message. Please try again.');
      }
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

      // Show preview dialog
      _showImagePreviewDialog(image);
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        _showErrorDialog('Error', 'Failed to pick image. Please try again.');
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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text(
                      'Send Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              // Image Preview
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Image.file(
                    File(image.path),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
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
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _sendImageMessage(image);
                        },
                        icon: const Icon(Icons.send, size: 20),
                        label: const Text('Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
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
    setState(() => _isUploadingImage = true);

    try {
      final imageUrl = await _chatService.uploadChatImage(
        imageFile: image,
        chatId: widget.chatId,
      );

      if (imageUrl != null) {
        await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .add({
          'senderId': _db.currentUserId,
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'image',
        });

        await _firestore.collection('chats').doc(widget.chatId).update({
          'lastMessage': '📷 Photo',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        await _chatService.sendMessageWithNotification(
          recipientId: widget.otherUserId,
          messageText: '📷 Sent a photo',
        );

        _scrollToBottom();
      } else {
        if (mounted) {
          _showErrorDialog('Upload Failed', 'Could not upload the image.');
        }
      }
    } catch (e) {
      print('Error sending image: $e');
      if (mounted) {
        _showErrorDialog('Error', 'Failed to send image. Please try again.');
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Send Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: AppColors.primary, size: 24),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library,
                        color: AppColors.primary, size: 24),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    if (_hasMarkedAsRead) return;

    try {
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: _db.currentUserId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in messagesSnapshot.docs) {
        await doc.reference.update({'read': true});
      }

      _hasMarkedAsRead = true;
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('OK',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await _showFloatingDeleteDialog(
      title: 'Delete Message',
      message: 'Are you sure you want to delete this message?',
      icon: Icons.chat_bubble_outline,
    );

    if (confirm == true) {
      _showLoadingDialog();

      try {
        await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .doc(messageId)
            .delete();

        final remainingMessages = await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (remainingMessages.docs.isEmpty) {
          await _firestore.collection('chats').doc(widget.chatId).delete();

          if (mounted) {
            Navigator.pop(context);
            Navigator.pop(context);

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _showResultDialog(
                  success: true,
                  successTitle: 'Message Deleted',
                  successMessage:
                      'The conversation has been removed as there are no messages left.',
                  failTitle: '',
                  failMessage: '',
                );
              }
            });
          }
        } else {
          final lastMsg = remainingMessages.docs.first.data();
          await _firestore.collection('chats').doc(widget.chatId).update({
            'lastMessage':
                lastMsg['type'] == 'image' ? '📷 Photo' : lastMsg['text'] ?? '',
            'lastMessageTime':
                lastMsg['timestamp'] ?? FieldValue.serverTimestamp(),
          });

          if (mounted) {
            Navigator.pop(context);
            _showResultDialog(
              success: true,
              successTitle: 'Message Deleted',
              successMessage: 'The message has been successfully deleted.',
              failTitle: '',
              failMessage: '',
            );
          }
        }
      } catch (e) {
        print('Error deleting message: $e');
        if (mounted) {
          Navigator.pop(context);
          _showResultDialog(
            success: false,
            successTitle: '',
            successMessage: '',
            failTitle: 'Failed to Delete',
            failMessage: 'Something went wrong. Please try again.',
          );
        }
      }
    }
  }

  Future<void> _deleteEntireChat() async {
    final confirm = await _showFloatingDeleteDialog(
      title: 'Delete Conversation',
      message:
          'Are you sure you want to delete your entire conversation with ${widget.otherUserName}? This action cannot be undone.',
      icon: Icons.forum_outlined,
    );

    if (confirm == true) {
      _showLoadingDialog();

      try {
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .get();

        for (var doc in messagesSnapshot.docs) {
          await doc.reference.delete();
        }

        await _firestore.collection('chats').doc(widget.chatId).delete();

        if (mounted) {
          Navigator.pop(context);
          Navigator.pop(context);

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showResultDialog(
                success: true,
                successTitle: 'Conversation Deleted',
                successMessage:
                    'The conversation has been successfully deleted.',
                failTitle: '',
                failMessage: '',
              );
            }
          });
        }
      } catch (e) {
        print('Error deleting chat: $e');
        if (mounted) {
          Navigator.pop(context);
          _showResultDialog(
            success: false,
            successTitle: '',
            successMessage: '',
            failTitle: 'Failed to Delete',
            failMessage: 'Something went wrong. Please try again.',
          );
        }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  void _showResultDialog({
    required bool success,
    required String successTitle,
    required String successMessage,
    required String failTitle,
    required String failMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: success
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  size: 48,
                  color: success ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                success ? successTitle : failTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                success ? successMessage : failMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Conversation Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 24),
                  ),
                  title: const Text(
                    'Delete Entire Conversation',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'This action cannot be undone',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteEntireChat();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error,
                        color: Colors.white, size: 48);
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
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

            // Real-time location retrieval
            String locationText = 'Location not set';
            bool hasLocation = false;

            if (otherUser != null) {
              // Check for direct latitude/longitude fields (current structure)
              if (otherUser['latitude'] != null &&
                  otherUser['longitude'] != null &&
                  otherUser['address'] != null &&
                  otherUser['address'].toString().isNotEmpty) {
                locationText = otherUser['address'];
                hasLocation = true;
              }
              // Fall back to cityState field
              else if (otherUser['cityState'] != null &&
                  otherUser['cityState'].toString().isNotEmpty) {
                locationText = otherUser['cityState'];
                hasLocation = true;
              }
              // Fall back to nested location object (old structure)
              else if (otherUser['location'] != null) {
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
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
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
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
                            color: hasLocation
                                ? Colors.red[400]
                                : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationText,
                              style: TextStyle(
                                color: hasLocation
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                                fontSize: 12,
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MessagesList(
              chatId: widget.chatId,
              currentUserId: _db.currentUserId ?? '',
              scrollController: _scrollController,
              onMarkMessagesAsRead: _markMessagesAsRead,
              onDeleteMessage: _deleteMessage,
              onImageTap: _showImagePreview,
            ),
          ),
          if (_isUploadingImage)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
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
