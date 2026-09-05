import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/providers/chat_providers.dart';
import 'package:thryfto/shared/widgets/skeleton_loaders.dart';
import 'package:thryfto/features/chat/widgets/offer_message_card.dart';

class MessagesList extends ConsumerStatefulWidget {
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
  ConsumerState<MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends ConsumerState<MessagesList> {
  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _surface = Color(0xFFFBFAFC);

  @override
  Widget build(BuildContext context) {
    // Use Riverpod provider instead of StreamBuilder
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));

    return messagesAsync.when(
      data: (messages) {
        // Filter messages based on deletedForTimestamps
        final chatDoc = ref.watch(
          StreamProvider.autoDispose<DocumentSnapshot?>((ref) {
            return FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .snapshots();
          }),
        );

        Timestamp? deletedTimestamp;
        chatDoc.whenData((snapshot) {
          if (snapshot != null && snapshot.exists) {
            final chatData = snapshot.data() as Map<String, dynamic>?;
            final deletedForTimestamps =
                chatData?['deletedForTimestamps'] as Map<String, dynamic>?;
            deletedTimestamp =
                deletedForTimestamps?[widget.currentUserId] as Timestamp?;
          }
        });

        final filteredMessages = messages.where((doc) {
          if (deletedTimestamp == null) return true;
          final messageData = doc.data() as Map<String, dynamic>;
          final messageTimestamp = messageData['timestamp'] as Timestamp?;
          return messageTimestamp == null ||
              messageTimestamp.compareTo(deletedTimestamp!) > 0;
        }).toList();

        if (filteredMessages.isEmpty) return _buildEmptyState();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onMarkMessagesAsRead();
        });

        return ListView.builder(
          controller: widget.scrollController,
          reverse: true,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          itemCount: filteredMessages.length,
          itemBuilder: (context, index) {
            final messageDoc = filteredMessages[index];
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
      loading: () => const MessageListSkeleton(),
      error: (error, stack) => Center(
        child: Text('Error loading messages: $error'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _line),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 30,
              color: _muted,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to start the conversation',
            style: TextStyle(
              fontSize: 13,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, String messageId,
      Map<String, dynamic> messageData, bool isMe, String messageType) {
    final timestamp = messageData['timestamp'] as Timestamp?;
    final timeText = timestamp != null
        ? '${timestamp.toDate().hour.toString().padLeft(2, '0')}:${timestamp.toDate().minute.toString().padLeft(2, '0')}'
        : '';

    final isStructuredOfferMessage =
        messageType == 'offer' || messageType == 'offer_update';

    return GestureDetector(
      onLongPress: isMe && !isStructuredOfferMessage
          ? () => widget.onDeleteMessage(messageId)
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
          child: messageType == 'image'
              ? _buildImageMessage(messageData, timeText, isMe)
              : messageType == 'offer'
                  ? OfferMessageCard(
                      offerId: messageData['offerId']?.toString() ?? '',
                      currentUserId: widget.currentUserId,
                    )
                  : messageType == 'offer_update'
                      ? _buildOfferUpdateMessage(
                          messageData,
                          isMe,
                          timeText,
                        )
                  : _buildTextMessage(messageData, isMe, timeText),
        ),
      ),
    );
  }

  Widget _buildOfferUpdateMessage(
    Map<String, dynamic> messageData,
    bool isMe,
    String timeText,
  ) {
    final status = messageData['offerStatus']?.toString() ?? 'updated';
    final amount = (messageData['amount'] as num?)?.toDouble() ?? 0;
    final label = switch (status) {
      'countered' => 'Counter offer · ₱${amount.toStringAsFixed(2)}',
      'accepted' => 'Offer accepted · ₱${amount.toStringAsFixed(2)}',
      'declined' => 'Offer declined · ₱${amount.toStringAsFixed(2)}',
      _ => 'Offer updated',
    };
    final icon = switch (status) {
      'countered' => Icons.swap_horiz_rounded,
      'accepted' => Icons.check_circle_outline_rounded,
      'declined' => Icons.cancel_outlined,
      _ => Icons.local_offer_outlined,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? _ink.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _muted),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: _ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (timeText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              timeText,
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextMessage(
      Map<String, dynamic> messageData, bool isMe, String timeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? _ink : Colors.white,
        border: isMe ? null : Border.all(color: _line),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 5),
          bottomRight: Radius.circular(isMe ? 5 : 18),
        ),
        boxShadow: isMe
            ? null
            : [
                BoxShadow(
                  color: _ink.withValues(alpha: 0.035),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(messageData['text'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : _ink,
                fontSize: 14.5,
                height: 1.32,
                fontWeight: FontWeight.w500,
              )),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(timeText,
                  style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[500],
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600)),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(messageData['read'] == true ? Icons.done_all : Icons.done,
                    size: 12, color: isMe ? Colors.white70 : _muted),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(
      Map<String, dynamic> messageData, String timeText, bool isMe) {
    final imageUrl = messageData['imageUrl'];
    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => widget.onImageTap(imageUrl), // Added widget. prefix
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: _line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, size: 12, color: _muted),
            const SizedBox(width: 4),
            Text(timeText,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                )),
            if (isMe) ...[
              const SizedBox(width: 4),
              Icon(messageData['read'] == true ? Icons.done_all : Icons.done,
                  size: 12, color: Colors.grey[500]),
            ],
          ],
        ),
      ],
    );
  }
}
