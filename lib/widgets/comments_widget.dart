import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:thryfto/shared/app_colors.dart';

class CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String currentUserId;
  final Function(String id) onDelete;
  final DatabaseService db;

  const CommentItem({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = comment['created_at'] as Timestamp?;
    final timeStr = timestamp != null ? DateFormat.jm().format(timestamp.toDate()) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RealtimeUserAvatar(
            userId: comment['user_id'],
            userName: comment['user_name'] ?? 'User',
            radius: 18,
            db: db,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment['user_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(comment['comment'] ?? '', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(timeStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    if (comment['user_id'] == currentUserId) ...[
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => onDelete(comment['id']),
                        child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RealtimeUserAvatar extends StatelessWidget {
  final String? userId;
  final String userName;
  final double radius;
  final DatabaseService db;

  const RealtimeUserAvatar({
    super.key,
    required this.userId,
    required this.userName,
    required this.radius,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null) return _staticAvatar(null);
    return StreamBuilder<Map<String, dynamic>?>(
      stream: db.getUserProfileStream(userId!),
      builder: (context, snapshot) {
        return _staticAvatar(snapshot.data?['profileImageUrl']);
      },
    );
  }

  Widget _staticAvatar(String? url) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
      child: (url == null || url.isEmpty)
          ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 12))
          : null,
    );
  }
}