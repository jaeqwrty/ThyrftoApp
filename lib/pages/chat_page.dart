import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/commonWidgets/empty_state.dart';
import 'package:thryfto/commonWidgets/error.dart';
import 'package:thryfto/commonWidgets/search_bar.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/pages/conversation_page.dart';

class ChatListPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ChatListPage({super.key, required this.user});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _db = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteConversation(String chatId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
            'Are you sure you want to delete your conversation with $username? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _db.deleteChat(chatId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Conversation deleted'
                  : 'Failed to delete conversation',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _showChatOptions(String chatId, String username) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Conversation',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConversation(chatId, username);
                },
              ),
              const SizedBox(height: 8),
            ],
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
          // Search Bar
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
          // Chat List
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: _db.currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const ErrorState(message: 'Unable to load messages');
        }

        final chatDocs = snapshot.data?.docs ?? [];

        // Sort client-side by last message time
        final chats = chatDocs.toList();
        chats.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          final bTime = (bData['lastMessageTime'] as Timestamp?)?.toDate() ??
              DateTime(2000);
          return bTime.compareTo(aTime);
        });

        if (chats.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet',
            subtitle: 'Start a conversation by messaging a seller',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chatData = chats[index].data() as Map<String, dynamic>;
            final chatId = chats[index].id;
            return _buildChatTile(chatId, chatData);
          },
        );
      },
    );
  }

  Widget _buildChatTile(String chatId, Map<String, dynamic> chatData) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != _db.currentUserId,
      orElse: () => '',
    );

    // Changed from FutureBuilder to StreamBuilder for real-time updates
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _db.getUserProfileStream(otherUserId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          // Show loading state
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 150,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final otherUser = userSnapshot.data;
        final fullName = otherUser?['fullName'] ?? otherUser?['full_name'];
        final username = otherUser?['username'];
        final profileImageUrl = otherUser?['profileImageUrl'] as String?;

        // Display full name if available, otherwise username
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
                    // Avatar with profile image
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF8B5CF6),
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
                    // Chat Info
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
                    // Time
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
