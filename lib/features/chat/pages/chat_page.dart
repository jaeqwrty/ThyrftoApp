import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/shared/widgets/empty_state.dart';
import 'package:thryfto/shared/widgets/error.dart';
import 'package:thryfto/core/utils/common_dialogs.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/core/providers/chat_providers.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';
import 'package:thryfto/shared/widgets/skeleton_loaders.dart';

class ChatListPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const ChatListPage({super.key, required this.user});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _page = Color(0xFFF6F3F8);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _accent = Color(0xFFA8752A);

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
      backgroundColor: _page,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                color: _ink,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Conversations with buyers and sellers',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search conversations',
          hintStyle: const TextStyle(
            color: Color(0xFFAAA3B5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: _muted),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: _surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _ink, width: 1.2),
          ),
        ),
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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          itemCount: filteredChats.length,
          itemBuilder: (context, index) {
            final chat = filteredChats[index];
            final chatId = chat.id;
            final chatData = chat.data() as Map<String, dynamic>;
            return _buildChatTile(chatId, chatData);
          },
        );
      },
      loading: () => const ChatListSkeleton(),
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
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  AppPageRoute.fadeThrough(
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
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    _buildAvatar(displayName, profileImageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMessage.isNotEmpty
                                ? lastMessage
                                : 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (lastMessageTime != null)
                      Text(
                        _formatTime(lastMessageTime.toDate()),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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

  Widget _buildAvatar(String displayName, String? profileImageUrl) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _accent.withValues(alpha: 0.45)),
      ),
      child: CircleAvatar(
        backgroundColor: _surface,
        backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
            ? NetworkImage(profileImageUrl)
            : null,
        child: (profileImageUrl == null || profileImageUrl.isEmpty)
            ? Text(
                initial,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildSkeletonTile() {
    return const ChatTileSkeleton();
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
