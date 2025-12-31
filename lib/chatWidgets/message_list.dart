import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/chatWidgets/messages_bubble.dart';

class MessagesList extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final ScrollController scrollController;
  final VoidCallback onMarkMessagesAsRead;
  final Function(String) onDeleteMessage;
  final Function(String) onImageTap;

  const MessagesList({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.scrollController,
    required this.onMarkMessagesAsRead,
    required this.onDeleteMessage,
    required this.onImageTap,
  });

  @override
  State<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<MessagesList> {
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
                MessageBubble(
                  message: messageData,
                  messageId: messageId,
                  isMe: isMe,
                  onDeleteMessage: widget.onDeleteMessage,
                  onImageTap: widget.onImageTap,
                ),
              ],
            );
          },
        );
      },
    );
  }
}