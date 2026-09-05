import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/core/services/notification_service.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  // Get comments stream for a specific listing
  Stream<List<Map<String, dynamic>>> getCommentsStream(String listingId) {
    return _db
        .collection('listings')
        .doc(listingId)
        .collection('comments')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                ...data,
                'id': doc.id,
              };
            }).toList());
  }

  // Add a new comment
  Future<void> addComment({
    required String listingId,
    required String userId,
    required String userName,
    required String comment,
  }) async {
    if (currentUserId == null || currentUserId != userId) {
      throw StateError('Comment author does not match the signed-in user');
    }

    // Create the source comment first so notification rules can verify it.
    final commentRef = _db
        .collection('listings')
        .doc(listingId)
        .collection('comments')
        .doc();
    await commentRef.set({
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
    });

    // Get listing details to find the seller
    final listingDoc = await _db.collection('listings').doc(listingId).get();
    if (listingDoc.exists) {
      final listingData = listingDoc.data();
      final sellerId = listingData?['seller_id'] as String?;
      
      // Only create notification if commenter is not the seller
      if (sellerId != null && sellerId != userId) {
        await _notificationService.createNotification(
          recipientId: sellerId,
          type: 'comment',
          title: '$userName commented on your listing',
          body: comment,
          relatedListingId: listingId,
          relatedUserId: userId,
          additionalData: {'comment_id': commentRef.id},
        );
      }
    }
  }

  // Delete a comment
  Future<void> deleteComment(String listingId, String commentId) async {
    await _db
        .collection('listings')
        .doc(listingId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
  Stream<int> getCommentCountStream(String listingId) {
  return _db
      .collection('listings')
      .doc(listingId)
      .collection('comments')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
}
}