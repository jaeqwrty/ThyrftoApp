import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/commonWidgets/empty_state.dart';
import 'package:thryfto/commonWidgets/error.dart';
import 'package:thryfto/commonWidgets/search_bar.dart';
import 'package:thryfto/shared/app_colors.dart';
import 'package:thryfto/providers/chat_providers.dart';
import 'package:thryfto/pages/conversation_page.dart';

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

    final confirm = await _showFloatingDeleteDialog(
      title: 'Delete Conversation',
      message:
          'Delete this conversation for yourself? $username will still have it.',
      icon: Icons.forum_outlined,
    );

    if (confirm == true) {
      _showLoadingDialog();

      try {
        final success = await chatService.deleteChat(chatId);

        if (mounted) {
          Navigator.pop(context);

          if (success) {
            _showResultDialog(
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
          _showResultDialog(
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

  void _showChatOptions(String chatId, String username) {
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
                    'Delete Conversation',
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
                    _deleteConversation(chatId, username);
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
