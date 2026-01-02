import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/global/app_colors.dart';

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
  late Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .snapshots(),
      builder: (context, chatSnapshot) {
        Timestamp? deletedTimestamp;

        if (chatSnapshot.hasData && chatSnapshot.data != null) {
          final chatData = chatSnapshot.data!.data() as Map<String, dynamic>?;
          final deletedForTimestamps =
              chatData?['deletedForTimestamps'] as Map<String, dynamic>?;
          deletedTimestamp =
              deletedForTimestamps?[widget.currentUserId] as Timestamp?;
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _messagesStream, // Use the persistent stream to stop flickering
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allMessages = snapshot.data?.docs ?? [];
            final messages = allMessages.where((doc) {
              if (deletedTimestamp == null) return true;
              final messageData = doc.data() as Map<String, dynamic>;
              final messageTimestamp = messageData['timestamp'] as Timestamp?;
              return messageTimestamp == null || messageTimestamp.compareTo(deletedTimestamp) > 0;
            }).toList();

            if (messages.isEmpty) return _buildEmptyState();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onMarkMessagesAsRead(); // Added widget. prefix
            });

            return ListView.builder(
              controller: widget.scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final messageDoc = messages[index];
                final messageData = messageDoc.data() as Map<String, dynamic>;
                final isMe = messageData['senderId'] == widget.currentUserId;
                final messageType = messageData['type'] ?? 'text';

                return _buildMessageBubble(
                  context,
                  messageDoc.id,
                  messageData,
                  isMe,
                  messageType,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text('Send a message to start the conversation',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, String messageId, Map<String, dynamic> messageData, bool isMe, String messageType) {
    final timestamp = messageData['timestamp'] as Timestamp?;
    final timeText = timestamp != null
        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    return GestureDetector(
      onLongPress: isMe ? () => widget.onDeleteMessage(messageId) : null, // Added widget. prefix
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: messageType == 'image'
              ? _buildImageMessage(messageData, timeText, isMe)
              : _buildTextMessage(messageData, isMe, timeText),
        ),
      ),
    );
  }

  Widget _buildTextMessage(Map<String, dynamic> messageData, bool isMe, String timeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(messageData['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timeText, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[500], fontSize: 11)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(messageData['read'] == true ? Icons.done_all : Icons.done, size: 12, color: isMe ? Colors.white70 : Colors.grey[500]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(Map<String, dynamic> messageData, String timeText, bool isMe) {
    final imageUrl = messageData['imageUrl'];
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => widget.onImageTap(imageUrl), // Added widget. prefix
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timeText, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(messageData['read'] == true ? Icons.done_all : Icons.done, size: 12, color: Colors.grey[500]),
            ],
          ],
        ),
      ],
    );
  }
}