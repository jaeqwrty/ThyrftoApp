import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/services/database_service.dart';

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
  bool _hasMarkedAsRead = false;

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
      });

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to Send', 'Could not send your message. Please try again.');
      }
    }
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
              child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                child: const Text('OK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
        // Delete the message
        await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .doc(messageId)
            .delete();

        // Update last message if needed
        final remainingMessages = await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (remainingMessages.docs.isEmpty) {
          // No messages left
          await _firestore.collection('chats').doc(widget.chatId).update({
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
        } else {
          // Update with the latest message
          final lastMsg = remainingMessages.docs.first.data();
          await _firestore.collection('chats').doc(widget.chatId).update({
            'lastMessage': lastMsg['text'] ?? '',
            'lastMessageTime': lastMsg['timestamp'] ?? FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          _showResultDialog(
            success: true,
            successTitle: 'Message Deleted',
            successMessage: 'The message has been successfully deleted.',
            failTitle: '',
            failMessage: '',
          );
        }
      } catch (e) {
        print('Error deleting message: $e');
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
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
      message: 'Are you sure you want to delete your entire conversation with ${widget.otherUserName}? This action cannot be undone.',
      icon: Icons.forum_outlined,
    );

    if (confirm == true) {
      _showLoadingDialog();
      
      try {
        // Delete all messages first
        final messagesSnapshot = await _firestore
            .collection('chats')
            .doc(widget.chatId)
            .collection('messages')
            .get();

        for (var doc in messagesSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete the chat document
        await _firestore.collection('chats').doc(widget.chatId).delete();

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context); // Go back to chat list
          
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showResultDialog(
                success: true,
                successTitle: 'Conversation Deleted',
                successMessage: 'The conversation has been successfully deleted.',
                failTitle: '',
                failMessage: '',
              );
            }
          });
        }
      } catch (e) {
        print('Error deleting chat: $e');
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
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

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF8B5CF6),
                  backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active now',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
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
            child: _MessagesList(
              chatId: widget.chatId,
              currentUserId: _db.currentUserId ?? '',
              scrollController: _scrollController,
              onMarkMessagesAsRead: _markMessagesAsRead,
              onDeleteMessage: _deleteMessage,
            ),
          ),
          _MessageInput(
            controller: _messageController,
            onSendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// Separate StatefulWidget for messages to isolate rebuilds
class _MessagesList extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final ScrollController scrollController;
  final VoidCallback onMarkMessagesAsRead;
  final Function(String) onDeleteMessage;

  const _MessagesList({
    required this.chatId,
    required this.currentUserId,
    required this.scrollController,
    required this.onMarkMessagesAsRead,
    required this.onDeleteMessage,
  });

  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> {
  bool _hasScrolled = false;

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (widget.scrollController.hasClients && !_hasScrolled) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        _hasScrolled = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data?.docs ?? [];

        if (messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onMarkMessagesAsRead();
            _scrollToBottom();
          });
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Start the conversation!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message to begin',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageDoc = messages[index];
            final messageData = messageDoc.data() as Map<String, dynamic>;
            final messageId = messageDoc.id;
            final isMe = messageData['senderId'] == widget.currentUserId;

            bool showTimestamp = index == 0;
            if (index > 0) {
              final prevMessageData =
                  messages[index - 1].data() as Map<String, dynamic>;
              final prevTimestamp = prevMessageData['timestamp'] as Timestamp?;
              final currentTimestamp = messageData['timestamp'] as Timestamp?;

              if (prevTimestamp != null && currentTimestamp != null) {
                final timeDiff = currentTimestamp
                    .toDate()
                    .difference(prevTimestamp.toDate());
                showTimestamp = timeDiff.inMinutes.abs() > 5;
              }
            }

            return Column(
              children: [
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _formatMessageTime(
                          (messageData['timestamp'] as Timestamp?)?.toDate()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                _MessageBubble(
                  message: messageData,
                  messageId: messageId,
                  isMe: isMe,
                  onDeleteMessage: widget.onDeleteMessage,
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final isToday = dateTime.day == now.day &&
        dateTime.month == now.month &&
        dateTime.year == now.year;
    final isYesterday = dateTime.day == yesterday.day &&
        dateTime.month == yesterday.month &&
        dateTime.year == yesterday.year;

    if (isToday) {
      return 'Today';
    } else if (isYesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Separate StatelessWidget for message bubble
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final String messageId;
  final bool isMe;
  final Function(String) onDeleteMessage;

  const _MessageBubble({
    required this.message,
    required this.messageId,
    required this.isMe,
    required this.onDeleteMessage,
  });

  void _showMessageOptions(BuildContext context) {
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
                    'Message Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
                  ),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDeleteMessage(messageId);
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

  @override
  Widget build(BuildContext context) {
    final timestamp = message['timestamp'] as Timestamp?;
    final timeText = timestamp != null
        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onLongPress: isMe ? () => _showMessageOptions(context) : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF8B5CF6) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message['text'] ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeText,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message['read'] == true ? Icons.done_all : Icons.done,
                      size: 12,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate StatefulWidget for message input to isolate typing state
class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendMessage;

  const _MessageInput({
    required this.controller,
    required this.onSendMessage,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  bool _isTyping = false;

  void _onMessageChanged(String value) {
    final isNowTyping = value.trim().isNotEmpty;
    if (isNowTyping != _isTyping) {
      setState(() => _isTyping = isNowTyping);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: widget.controller,
                  onChanged: _onMessageChanged,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: _isTyping
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              widget.controller.clear();
                              setState(() => _isTyping = false);
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isTyping ? widget.onSendMessage : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _isTyping ? const Color(0xFF8B5CF6) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _isTyping ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}