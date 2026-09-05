import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _ratingsRef(String sellerId) {
    return _firestore
        .collection('users')
        .doc(sellerId)
        .collection('ratings');
  }

  double? _validRatingValue(Map<String, dynamic> data) {
    final value = data['rating'];
    if (value is! num) return null;
    final rating = value.toDouble();
    if (!rating.isFinite || rating < 1 || rating > 5) return null;
    return rating;
  }

  Map<String, dynamic> _calculateStats(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    double total = 0;
    int count = 0;

    for (final document in documents) {
      final rating = _validRatingValue(document.data());
      if (rating == null) continue;
      total += rating;
      count++;
    }

    return {
      'average_rating': count == 0 ? 0.0 : total / count,
      'ratings_count': count,
    };
  }

  /// Creates or updates the signed-in user's single rating for a seller.
  Future<bool> rateSeller({
    required String sellerId,
    required double rating,
    String? review,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || currentUserId == sellerId) return false;
    if (!rating.isFinite || rating < 1 || rating > 5) return false;

    final normalizedReview = (review ?? '').trim();
    if (normalizedReview.length > 1000) return false;

    try {
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUserId).get();
      final sellerDoc = await _firestore.collection('users').doc(sellerId).get();
      if (!currentUserDoc.exists || !sellerDoc.exists) return false;

      final userData = currentUserDoc.data();
      final userName = userData?['fullName'] ??
          userData?['full_name'] ??
          userData?['username'] ??
          'Anonymous';
      final userImage = userData?['profileImageUrl'] ?? '';

      final ratingRef = _ratingsRef(sellerId).doc(currentUserId);
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(ratingRef);
        final data = <String, dynamic>{
          'rating': rating,
          'review': normalizedReview,
          'reviewer_id': currentUserId,
          'reviewer_name': userName,
          'reviewer_image': userImage,
          'updated_at': FieldValue.serverTimestamp(),
        };

        if (!existing.exists) {
          data['created_at'] = FieldValue.serverTimestamp();
        }

        transaction.set(ratingRef, data, SetOptions(merge: true));
      });

      return true;
    } catch (e) {
      print('Error rating seller: $e');
      return false;
    }
  }

  /// Gets the signed-in user's rating for a seller.
  Future<Map<String, dynamic>?> getUserRating(String sellerId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return null;

    try {
      final doc = await _ratingsRef(sellerId).doc(currentUserId).get();
      final data = doc.data();
      if (!doc.exists || data == null || _validRatingValue(data) == null) {
        return null;
      }
      return {'id': doc.id, ...data};
    } catch (e) {
      print('Error getting user rating: $e');
      return null;
    }
  }

  /// Gets all valid ratings for a seller in realtime.
  Stream<List<Map<String, dynamic>>> getSellerRatings(String sellerId) {
    return _ratingsRef(sellerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => _validRatingValue(doc.data()) != null)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Derives rating statistics from rating documents instead of writable
  /// aggregate fields on the seller profile.
  Stream<Map<String, dynamic>> getSellerRatingStatsStream(String sellerId) {
    return _ratingsRef(sellerId).snapshots().map((snapshot) {
      return _calculateStats(snapshot.docs);
    });
  }

  /// Gets rating statistics from the source rating documents.
  Future<Map<String, dynamic>> getSellerRatingStats(String sellerId) async {
    try {
      final snapshot = await _ratingsRef(sellerId).get();
      return _calculateStats(snapshot.docs);
    } catch (e) {
      print('Error getting rating stats: $e');
      return {
        'average_rating': 0.0,
        'ratings_count': 0,
      };
    }
  }

  /// Deletes only the signed-in user's rating for the seller.
  Future<bool> deleteRating(String sellerId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      await _ratingsRef(sellerId).doc(currentUserId).delete();
      return true;
    } catch (e) {
      print('Error deleting rating: $e');
      return false;
    }
  }
}
