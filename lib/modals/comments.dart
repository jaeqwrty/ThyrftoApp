import 'package:flutter/material.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsModal extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> user;

  const CommentsModal({
    super.key,
    required this.listingId,
    required this.user,
  });

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  // Reply state
  String? _replyingToCommentId;
  String? _replyingToUserName;
  final Map<String, bool> _showAllReplies = {};

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = (widget.user['uid'] as String?) ??
          (widget.user['id'] as String?) ??
          _db.currentUserId;

      if (userId == null) {
        throw Exception('User ID is required');
      }

      final userName = (widget.user['fullName'] as String?) ??
          (widget.user['full_name'] as String?) ??
          (widget.user['username'] as String?) ??
          (widget.user['email'] as String?)?.split('@')[0] ??
          'User';

      if (_replyingToCommentId != null) {
        // Add reply
        await _db.addReply(
          listingId: widget.listingId,
          commentId: _replyingToCommentId!,
          userId: userId,
          userName: userName,
          reply: _commentController.text.trim(),
        );
      } else {
        // Add comment
        await _db.addCommentWithNotification(
          listingId: widget.listingId,
          userId: userId,
          userName: userName,
          comment: _commentController.text.trim(),
        );
      }

      _commentController.clear();
      _cancelReply();

      // Scroll to bottom after adding comment
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _startReply(String commentId, String userName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUserName = userName;
    });
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  void _toggleShowAllReplies(String commentId) {
    setState(() {
      _showAllReplies[commentId] = !(_showAllReplies[commentId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getComments(widget.listingId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final currentUserId = (widget.user['uid'] as String?) ??
                        (widget.user['id'] as String?) ??
                        _db.currentUserId;
                    final isOwner = currentUserId != null &&
                        comment['user_id'] == currentUserId;

                    return _buildCommentItem(comment, isOwner);
                  },
                );
              },
            ),
          ),

          // Reply Preview Banner
          if (_replyingToCommentId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  top: BorderSide(color: Colors.blue.shade100),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to $_replyingToUserName',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Comment Input
          Container(
            padding: const EdgeInsets.all(16),
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
                  _buildUserAvatar(
                    imageUrl: widget.user['profileImageUrl'] as String?,
                    userName: _getUserName(),
                    radius: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        hintText: _replyingToCommentId != null
                            ? 'Write a reply...'
                            : 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide:
                              const BorderSide(color: Color(0xFF8B5CF6)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          color: const Color(0xFF8B5CF6),
                          onPressed: _submitComment,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, bool isOwner) {
    final userName = comment['user_name'] ?? 'Unknown';
    final commentText = comment['comment'] ?? '';
    final timestamp = comment['created_at'] as Timestamp?;
    final timeAgo =
        timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Just now';
    final commentId = comment['id'];
    final replies =
        (comment['replies'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            [];

    final showAll = _showAllReplies[commentId] ?? false;
    final visibleReplies =
        showAll || replies.length <= 3 ? replies : replies.take(3).toList();
    final hiddenCount = replies.length > 3 && !showAll ? replies.length - 3 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserAvatar(
                imageUrl: comment['user_profile_image'] as String?,
                userName: userName,
                radius: 18,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      commentText,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _startReply(commentId, userName),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _deleteComment(commentId),
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (replies.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          Text(
                            '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Replies Section
        if (replies.isNotEmpty) ...[
          ...visibleReplies.map((reply) => _buildReplyItem(reply, commentId)),

          // Show more/less button
          if (replies.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 58, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () => _toggleShowAllReplies(commentId),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showAll
                          ? 'Show less'
                          : 'View $hiddenCount more ${hiddenCount == 1 ? 'reply' : 'replies'}',
                      style: TextStyle(
                        color: const Color(0xFF8B5CF6),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildReplyItem(Map<String, dynamic> reply, String parentCommentId) {
    final userName = reply['user_name'] ?? 'Unknown';
    final replyText = reply['reply'] ?? '';
    final timestamp = reply['created_at'] as Timestamp?;
    final timeAgo =
        timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Just now';

    final currentUserId = (widget.user['uid'] as String?) ??
        (widget.user['id'] as String?) ??
        _db.currentUserId;
    final isOwner = currentUserId != null && reply['user_id'] == currentUserId;

    return Padding(
      padding: const EdgeInsets.only(left: 58, right: 16, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(
            imageUrl: reply['user_profile_image'] as String?,
            userName: userName,
            radius: 14,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  replyText,
                  style: const TextStyle(fontSize: 13),
                ),
                if (isOwner)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () => _deleteReply(parentCommentId, reply['id']),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
            'Are you sure you want to delete this comment and all its replies?'),
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

    if (confirmed == true) {
      try {
        await _db.deleteComment(widget.listingId, commentId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete comment: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteReply(String commentId, String replyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
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

    if (confirmed == true) {
      try {
        await _db.deleteReply(widget.listingId, commentId, replyId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete reply: $e')),
          );
        }
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getUserName() {
    return (widget.user['fullName'] as String?) ??
        (widget.user['full_name'] as String?) ??
        (widget.user['username'] as String?) ??
        (widget.user['email'] as String?)?.split('@')[0] ??
        'User';
  }

  Widget _buildUserAvatar({
    required String? imageUrl,
    required String userName,
    required double radius,
  }) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (_, __) {},
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
        ),
      );
    }

    // Fallback to initial
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF8B5CF6),
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
