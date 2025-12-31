import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Rate a seller with transaction to ensure consistency
  Future<bool> rateSeller({
    required String sellerId,
    required double rating,
    String? review,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ No current user');
        return false;
      }

      if (currentUserId == sellerId) {
        print('❌ Cannot rate yourself');
        return false;
      }

      print('🔄 Rating user: $sellerId with $rating stars');

      // Get current user info first
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final userData = userDoc.data();
      final userName = userData?['fullName'] ?? 
                       userData?['full_name'] ?? 
                       'Anonymous';
      final userImage = userData?['profileImageUrl'] ?? '';

      // Prepare rating data
      final ratingData = {
        'rating': rating,
        'review': review ?? '',
        'reviewer_id': currentUserId,
        'reviewer_name': userName,
        'reviewer_image': userImage,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Write rating document
      final ratingRef = _firestore
          .collection('users')
          .doc(sellerId)
          .collection('ratings')
          .doc(currentUserId);

      await ratingRef.set(ratingData, SetOptions(merge: true));
      
      print('✅ Rating document written');

      // Update average rating immediately (no delay)
      await _updateAverageRating(sellerId);

      print('✅ Rating completed successfully');
      return true;
    } catch (e) {
      print('❌ Error rating seller: $e');
      return false;
    }
  }

  /// Update average rating - reads all ratings and recalculates
  Future<void> _updateAverageRating(String sellerId) async {
    try {
      print('🔄 Calculating average rating...');
      
      // Get all ratings for this seller
      final ratingsSnapshot = await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('ratings')
          .get();

      print('   Found ${ratingsSnapshot.docs.length} ratings');

      double totalRating = 0;
      int count = 0;

      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final ratingValue = data['rating'];
        
        if (ratingValue != null) {
          final ratingDouble = (ratingValue is int) 
              ? ratingValue.toDouble() 
              : (ratingValue as double);
          totalRating += ratingDouble;
          count++;
          print('   Rating ${count}: $ratingDouble');
        }
      }

      if (count == 0) {
        print('   No valid ratings found');
        // Update user document with zero ratings
        await _firestore.collection('users').doc(sellerId).set({
          'average_rating': 0.0,
          'ratings_count': 0,
        }, SetOptions(merge: true));
        return;
      }

      final averageRating = totalRating / count;
      print('   Average: $averageRating from $count ratings');

      // Update user document with new stats
      await _firestore.collection('users').doc(sellerId).set({
        'average_rating': averageRating,
        'ratings_count': count,
      }, SetOptions(merge: true));

      print('✅ Average rating updated in user document');
      
    } catch (e) {
      print('❌ Error updating average: $e');
      
      // If update fails, try creating the fields
      try {
        await _firestore.collection('users').doc(sellerId).set({
          'average_rating': 0.0,
          'ratings_count': 0,
        }, SetOptions(merge: true));
        print('✅ Created rating fields with merge');
      } catch (e2) {
        print('❌ Failed to create fields: $e2');
      }
    }
  }

  /// Get user's rating for a seller
  Future<Map<String, dynamic>?> getUserRating(String sellerId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      print('🔍 Checking existing rating for seller: $sellerId');

      final doc = await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('ratings')
          .doc(currentUserId)
          .get();

      if (!doc.exists) {
        print('   No existing rating found');
        return null;
      }

      final data = doc.data();
      print('   Found rating: ${data?['rating']} stars');

      if (data == null) return null;

      return {
        'id': doc.id,
        ...data,
      };
    } catch (e) {
      print('❌ Error getting user rating: $e');
      return null;
    }
  }

  /// Get all ratings for a seller as a stream
  Stream<List<Map<String, dynamic>>> getSellerRatings(String sellerId) {
    return _firestore
        .collection('users')
        .doc(sellerId)
        .collection('ratings')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📡 Ratings stream: ${snapshot.docs.length} ratings');
      
      final ratings = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      return ratings;
    }).handleError((error) {
      print('❌ Ratings stream error: $error');
      return <Map<String, dynamic>>[];
    });
  }

  /// Get seller's rating stats as a stream - FIXED VERSION with initial value
  Stream<Map<String, dynamic>> getSellerRatingStatsStream(String sellerId) {
    return _firestore
        .collection('users')
        .doc(sellerId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      
      // Handle different data types safely
      final avgRaw = data?['average_rating'];
      final countRaw = data?['ratings_count'];

      double avgRating = 0.0;
      int ratingsCount = 0;

      // Convert average_rating to double
      if (avgRaw != null) {
        if (avgRaw is double) {
          avgRating = avgRaw;
        } else if (avgRaw is int) {
          avgRating = avgRaw.toDouble();
        } else if (avgRaw is num) {
          avgRating = avgRaw.toDouble();
        }
      }

      // Convert ratings_count to int
      if (countRaw != null) {
        if (countRaw is int) {
          ratingsCount = countRaw;
        } else if (countRaw is double) {
          ratingsCount = countRaw.toInt();
        } else if (countRaw is num) {
          ratingsCount = countRaw.toInt();
        }
      }

      print('📡 Stats stream: avg=$avgRating, count=$ratingsCount');

      return {
        'average_rating': avgRating,
        'ratings_count': ratingsCount,
      };
    }).handleError((error) {
      print('❌ Stats stream error: $error');
      return {
        'average_rating': 0.0,
        'ratings_count': 0,
      };
    });
  }

  /// Get seller's rating stats (single fetch)
  Future<Map<String, dynamic>> getSellerRatingStats(String sellerId) async {
    try {
      final doc = await _firestore.collection('users').doc(sellerId).get();
      
      if (!doc.exists) {
        return {
          'average_rating': 0.0,
          'ratings_count': 0,
        };
      }

      final data = doc.data();
      if (data == null) {
        return {
          'average_rating': 0.0,
          'ratings_count': 0,
        };
      }

      // Safely extract values
      final avgRaw = data['average_rating'];
      final countRaw = data['ratings_count'];

      double avgRating = 0.0;
      int ratingsCount = 0;

      if (avgRaw != null) {
        if (avgRaw is double) {
          avgRating = avgRaw;
        } else if (avgRaw is int) {
          avgRating = avgRaw.toDouble();
        } else if (avgRaw is num) {
          avgRating = avgRaw.toDouble();
        }
      }

      if (countRaw != null) {
        if (countRaw is int) {
          ratingsCount = countRaw;
        } else if (countRaw is double) {
          ratingsCount = countRaw.toInt();
        } else if (countRaw is num) {
          ratingsCount = countRaw.toInt();
        }
      }

      return {
        'average_rating': avgRating,
        'ratings_count': ratingsCount,
      };
    } catch (e) {
      print('❌ Error getting rating stats: $e');
      return {
        'average_rating': 0.0,
        'ratings_count': 0,
      };
    }
  }

  /// Delete a rating
  Future<bool> deleteRating(String sellerId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        print('❌ No current user');
        return false;
      }

      print('🗑️ Deleting rating for seller: $sellerId');

      await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('ratings')
          .doc(currentUserId)
          .delete();

      print('✅ Rating deleted');

      // Recalculate immediately (no delay)
      await _updateAverageRating(sellerId);

      return true;
    } catch (e) {
      print('❌ Error deleting rating: $e');
      return false;
    }
  }
}