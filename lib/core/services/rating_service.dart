import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _ratingsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('ratings');
  }

  String _reviewId(String transactionId, String reviewerId) {
    return '${transactionId}_$reviewerId';
  }

  double? _validRatingValue(Map<String, dynamic> data) {
    final value = data['rating'];
    final transactionId = data['transaction_id'];
    final reviewerId = data['reviewer_id'];
    final revieweeId = data['reviewee_id'];
    if (value is! num ||
        transactionId is! String ||
        transactionId.isEmpty ||
        reviewerId is! String ||
        reviewerId.isEmpty ||
        revieweeId is! String ||
        revieweeId.isEmpty) {
      return null;
    }

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

  /// Returns completed marketplace transactions between the signed-in user
  /// and [otherUserId], newest first. Each entry contains an optional
  /// `existing_review` created by the current user for that transaction.
  Future<List<Map<String, dynamic>>> getCompletedTransactionsWithUser(
    String otherUserId,
  ) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null ||
        otherUserId.isEmpty ||
        currentUserId == otherUserId) {
      return [];
    }

    try {
      final results = await Future.wait([
        _firestore
            .collection('transactions')
            .where('buyer_id', isEqualTo: currentUserId)
            .get(),
        _firestore
            .collection('transactions')
            .where('seller_id', isEqualTo: currentUserId)
            .get(),
        _ratingsRef(otherUserId)
            .where('reviewer_id', isEqualTo: currentUserId)
            .get(),
      ]);

      final buyerTransactions =
          results[0] as QuerySnapshot<Map<String, dynamic>>;
      final sellerTransactions =
          results[1] as QuerySnapshot<Map<String, dynamic>>;
      final existingReviews = results[2] as QuerySnapshot<Map<String, dynamic>>;

      final reviewsByTransaction = <String, Map<String, dynamic>>{};
      for (final reviewDoc in existingReviews.docs) {
        final review = reviewDoc.data();
        final transactionId = review['transaction_id']?.toString();
        if (transactionId == null || transactionId.isEmpty) continue;
        if (_validRatingValue(review) == null) continue;
        reviewsByTransaction[transactionId] = {
          'id': reviewDoc.id,
          ...review,
        };
      }

      final transactionsById = <String, Map<String, dynamic>>{};

      void collect(
        Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
      ) {
        for (final doc in documents) {
          final data = doc.data();
          if (data['status'] != 'completed') continue;

          final buyerId = data['buyer_id']?.toString();
          final sellerId = data['seller_id']?.toString();
          final isCurrentBuyer =
              buyerId == currentUserId && sellerId == otherUserId;
          final isCurrentSeller =
              sellerId == currentUserId && buyerId == otherUserId;
          if (!isCurrentBuyer && !isCurrentSeller) continue;

          transactionsById[doc.id] = {
            'id': doc.id,
            ...data,
            'reviewer_role': isCurrentBuyer ? 'buyer' : 'seller',
            'reviewee_role': isCurrentBuyer ? 'seller' : 'buyer',
            'existing_review': reviewsByTransaction[doc.id],
          };
        }
      }

      collect(buyerTransactions.docs);
      collect(sellerTransactions.docs);

      final transactions = transactionsById.values.toList();
      transactions.sort((a, b) {
        int millis(Map<String, dynamic> value) {
          final timestamp = value['completed_at'];
          return timestamp is Timestamp ? timestamp.millisecondsSinceEpoch : 0;
        }

        return millis(b).compareTo(millis(a));
      });
      return transactions;
    } catch (e) {
      print('Error getting completed transactions for reviews: $e');
      return [];
    }
  }

  /// Creates or updates one verified review for one completed transaction.
  /// The current user must be one transaction participant and [revieweeId]
  /// must be the other participant.
  Future<Map<String, dynamic>?> submitTransactionReview({
    required String revieweeId,
    required String transactionId,
    required double rating,
    String? review,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null ||
        currentUserId == revieweeId ||
        revieweeId.isEmpty ||
        transactionId.isEmpty) {
      return null;
    }
    if (!rating.isFinite || rating < 1 || rating > 5) return null;

    final normalizedReview = (review ?? '').trim();
    if (normalizedReview.length > 1000) return null;

    final ratingRef =
        _ratingsRef(revieweeId).doc(_reviewId(transactionId, currentUserId));
    final transactionRef =
        _firestore.collection('transactions').doc(transactionId);

    try {
      late String listingId;
      late String listingTitle;
      late String reviewerRole;
      late String revieweeRole;
      var created = false;

      await _firestore.runTransaction((transaction) async {
        final transactionSnapshot = await transaction.get(transactionRef);
        if (!transactionSnapshot.exists) {
          throw StateError('Transaction no longer exists');
        }

        final transactionData = transactionSnapshot.data()!;
        if (transactionData['status'] != 'completed') {
          throw StateError('Reviews are available only after a completed transaction');
        }

        final buyerId = transactionData['buyer_id']?.toString();
        final sellerId = transactionData['seller_id']?.toString();
        if (buyerId == currentUserId && sellerId == revieweeId) {
          reviewerRole = 'buyer';
          revieweeRole = 'seller';
        } else if (sellerId == currentUserId && buyerId == revieweeId) {
          reviewerRole = 'seller';
          revieweeRole = 'buyer';
        } else {
          throw StateError('You are not eligible to review this user for this transaction');
        }

        listingId = transactionData['listing_id']?.toString() ?? '';
        listingTitle =
            transactionData['listing_title']?.toString() ?? 'Listing';
        if (listingId.isEmpty) {
          throw StateError('Transaction listing information is incomplete');
        }

        final currentUserDoc = await transaction.get(
          _firestore.collection('users').doc(currentUserId),
        );
        final revieweeDoc = await transaction.get(
          _firestore.collection('users').doc(revieweeId),
        );
        if (!currentUserDoc.exists || !revieweeDoc.exists) {
          throw StateError('User profile is unavailable');
        }

        final existing = await transaction.get(ratingRef);
        created = !existing.exists;

        final data = <String, dynamic>{
          'transaction_id': transactionId,
          'listing_id': listingId,
          'listing_title': listingTitle,
          'reviewer_id': currentUserId,
          'reviewee_id': revieweeId,
          'reviewer_role': reviewerRole,
          'reviewee_role': revieweeRole,
          'rating': rating,
          'review': normalizedReview,
          'updated_at': FieldValue.serverTimestamp(),
          if (!existing.exists) 'created_at': FieldValue.serverTimestamp(),
        };

        transaction.set(ratingRef, data, SetOptions(merge: true));
      });

      return {
        'review_id': ratingRef.id,
        'transaction_id': transactionId,
        'listing_id': listingId,
        'listing_title': listingTitle,
        'reviewer_role': reviewerRole,
        'reviewee_role': revieweeRole,
        'created': created,
      };
    } catch (e) {
      print('Error submitting transaction review: $e');
      return null;
    }
  }

  /// Gets the signed-in user's verified review for one transaction.
  Future<Map<String, dynamic>?> getTransactionReview({
    required String revieweeId,
    required String transactionId,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || transactionId.isEmpty) return null;

    try {
      final doc = await _ratingsRef(revieweeId)
          .doc(_reviewId(transactionId, currentUserId))
          .get();
      final data = doc.data();
      if (!doc.exists || data == null || _validRatingValue(data) == null) {
        return null;
      }
      return {'id': doc.id, ...data};
    } catch (e) {
      print('Error getting transaction review: $e');
      return null;
    }
  }

  /// Gets all verified transaction reviews for a user in realtime.
  Stream<List<Map<String, dynamic>>> getUserReviews(String userId) {
    return _ratingsRef(userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => _validRatingValue(doc.data()) != null)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  /// Derives reputation statistics only from verified transaction reviews.
  Stream<Map<String, dynamic>> getUserRatingStatsStream(String userId) {
    return _ratingsRef(userId).snapshots().map((snapshot) {
      return _calculateStats(snapshot.docs);
    });
  }

  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    try {
      final snapshot = await _ratingsRef(userId).get();
      return _calculateStats(snapshot.docs);
    } catch (e) {
      print('Error getting rating stats: $e');
      return {
        'average_rating': 0.0,
        'ratings_count': 0,
      };
    }
  }

  /// Deletes only the signed-in user's review for one completed transaction.
  Future<bool> deleteTransactionReview({
    required String revieweeId,
    required String transactionId,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null || transactionId.isEmpty) return false;

    try {
      await _ratingsRef(revieweeId)
          .doc(_reviewId(transactionId, currentUserId))
          .delete();
      return true;
    } catch (e) {
      print('Error deleting transaction review: $e');
      return false;
    }
  }

  // Compatibility aliases for existing profile widgets while the product UI
  // continues using the familiar "rating" terminology.
  Stream<List<Map<String, dynamic>>> getSellerRatings(String userId) =>
      getUserReviews(userId);

  Stream<Map<String, dynamic>> getSellerRatingStatsStream(String userId) =>
      getUserRatingStatsStream(userId);

  Future<Map<String, dynamic>> getSellerRatingStats(String userId) =>
      getUserRatingStats(userId);
}
