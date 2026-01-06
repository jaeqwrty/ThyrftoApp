import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/shared/widgets/empty_state.dart';
import 'package:thryfto/shared/widgets/error.dart';
import 'package:thryfto/shared/widgets/search_bar.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/utils/common_dialogs.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/core/providers/chat_providers.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';

class ChatListPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const ChatListPage({super.key, required this.user});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteConversation(String chatId, String username) async {
    final chatService = ref.read(chatServiceProvider);

    final confirm = await CommonDialogs.showDeleteConfirmationDialog(
      context,
      title: 'Delete Conversation',
      message:
          'Delete this conversation for yourself? $username will still have it.',
      icon: Icons.forum_outlined,
    );

    if (confirm == true) {
      CommonDialogs.showLoadingDialog(context);

      try {
        final success = await chatService.deleteChat(chatId);

        if (mounted) {
          Navigator.pop(context);

          if (success) {
            CommonDialogs.showResultDialog(
              context,
              success: true,
              successTitle: 'Conversation Deleted',
              successMessage:
                  'The conversation has been removed from your chat list.',
              failTitle: '',
              failMessage: '',
            );
          } else {
            throw Exception('Failed to delete conversation');
          }
        }
      } catch (e) {
        print('Error deleting conversation: $e');
        if (mounted) {
          Navigator.pop(context);
          CommonDialogs.showResultDialog(
            context,
            success: false,
            successTitle: '',
            successMessage: '',
            failTitle: 'Failed to Delete',
            failMessage: 'Something went wrong: ${e.toString()}',
          );
        }
      }
    }
  }

  // Dialog methods now use CommonDialogs utility

  void _showChatOptions(String chatId, String username) {
    CommonModals.showOptionsModal(
      context,
      title: 'Conversation Options',
      items: [
        OptionsModalItem.delete(
          title: 'Delete Conversation',
          subtitle: 'This action cannot be undone',
          onTap: () => _deleteConversation(chatId, username),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Search conversations...',
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              showClearButton: _searchQuery.isNotEmpty,
            ),
          ),
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    final chatsAsync = ref.watch(chatListProvider);

    return chatsAsync.when(
      data: (chats) {
        // Filter chats based on deleted status and search query
        final validChats = chats.where((chat) {
          final chatData = chat.data() as Map<String, dynamic>;
          final deletedForTimestamps =
              chatData['deletedForTimestamps'] as Map<String, dynamic>?;
          final currentUserId = ref.read(chatServiceProvider).currentUserId;

          if (deletedForTimestamps != null &&
              deletedForTimestamps.containsKey(currentUserId)) {
            return false;
          }

          return true;
        }).toList();

        // Filter by search query
        final filteredChats = validChats.where((chat) {
          if (_searchQuery.isEmpty) return true;

          final chatData = chat.data() as Map<String, dynamic>;
          final participants = List<String>.from(chatData['participants']);
          final otherUserId = participants.firstWhere(
            (id) => id != ref.read(chatServiceProvider).currentUserId,
            orElse: () => '',
          );

          // You could expand this to search by user name if you fetch user data
          return otherUserId.toLowerCase().contains(_searchQuery);
        }).toList();

        if (filteredChats.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet',
            subtitle: 'Start a conversation by messaging a seller',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            final chatId = chat.id;
            final chatData = chat.data() as Map<String, dynamic>;
            return _buildChatTile(chatId, chatData);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(
        message: 'Error loading chats: ${error.toString()}',
      ),
    );
  }

  Widget _buildChatTile(String chatId, Map<String, dynamic> chatData) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final chatService = ref.read(chatServiceProvider);
    final dbService = ref.read(databaseServiceProvider);

    final otherUserId = participants.firstWhere(
      (id) => id != chatService.currentUserId,
      orElse: () => '',
    );

    return StreamBuilder<Map<String, dynamic>?>(
      stream: dbService.getUserProfileStream(otherUserId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonTile();
        }

        final otherUser = userSnapshot.data;
        final fullName = otherUser?['fullName'] ?? otherUser?['full_name'];
        final username = otherUser?['username'];
        final profileImageUrl = otherUser?['profileImageUrl'] as String?;

        final displayName = fullName ?? username ?? 'Unknown';
        final lastMessage = chatData['lastMessage'] ?? '';
        final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;

        // Filter by search query
        if (_searchQuery.isNotEmpty &&
            !displayName.toLowerCase().contains(_searchQuery)) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationPage(
                      chatId: chatId,
                      otherUserId: otherUserId,
                      otherUserName: displayName,
                      currentUser: widget.user,
                    ),
                  ),
                );
              },
              onLongPress: () {
                _showChatOptions(chatId, displayName);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      backgroundImage: (profileImageUrl != null &&
                              profileImageUrl.isNotEmpty)
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child:
                          (profileImageUrl == null || profileImageUrl.isEmpty)
                              ? Text(
                                  displayName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lastMessage.isNotEmpty
                                ? lastMessage
                                : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (lastMessageTime != null)
                      Text(
                        _formatTime(lastMessageTime.toDate()),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(radius: 24, backgroundColor: Colors.grey[200]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 100, height: 16, color: Colors.grey[200]),
                  const SizedBox(height: 6),
                  Container(width: 150, height: 14, color: Colors.grey[100]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
