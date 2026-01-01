import 'package:cloud_firestore/cloud_firestore.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    await _db.collection('listings').doc(listingId).collection('comments').add({
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'created_at': FieldValue.serverTimestamp(),
    });
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