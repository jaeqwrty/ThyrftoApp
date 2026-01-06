import 'package:flutter/material.dart';
import 'package:thryfto/core/services/comments_service.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/shared/widgets/comments_widget.dart';
import 'package:thryfto/core/constants/app_colors.dart';

class CommentsModal extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> user;

  const CommentsModal({super.key, required this.listingId, required this.user});

  @override
  State<CommentsModal> createState() => _CommentsModalState();
}

class _CommentsModalState extends State<CommentsModal> {
  final CommentService _commentService = CommentService();
  final DatabaseService _db = DatabaseService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late Stream<List<Map<String, dynamic>>> _commentsStream;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentsStream = _commentService.getCommentsStream(widget.listingId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    
    try {
      await _commentService.addComment(
        listingId: widget.listingId,
        userId: _db.currentUserId!,
        userName: widget.user['fullName'] ?? 'User',
        comment: text,
      );
      _commentController.clear();
      _focusNode.unfocus();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Comments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          Flexible(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No comments yet. Start the conversation!'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) => CommentItem(
                    key: ValueKey(comments[index]['id']),
                    comment: comments[index],
                    currentUserId: _db.currentUserId!,
                    db: _db,
                    onDelete: (id) => _commentService.deleteComment(widget.listingId, id),
                  ),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          IconButton(
            onPressed: _isSubmitting ? null : _submitComment,
            icon: Icon(Icons.send, color: _isSubmitting ? Colors.grey : AppColors.primary),
          ),
        ],
      ),
    );
  }
}