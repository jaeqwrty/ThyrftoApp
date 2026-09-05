import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Add a seller to favorites
  Future<bool> addToFavorites(String sellerId) async {
    try {
      if (_currentUserId == null) return false;

      await _firestore
          .collection('favorites')
          .doc('${_currentUserId}_$sellerId')
          .set({
        'user_id': _currentUserId,
        'seller_id': sellerId,
        'created_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove a seller from favorites
  Future<bool> removeFromFavorites(String sellerId) async {
    try {
      if (_currentUserId == null) return false;

      await _firestore
          .collection('favorites')
          .doc('${_currentUserId}_$sellerId')
          .delete();

      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  /// Check if a seller is favorited
  Future<bool> isFavorited(String sellerId) async {
    try {
      if (_currentUserId == null) return false;

      final doc = await _firestore
          .collection('favorites')
          .doc('${_currentUserId}_$sellerId')
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  /// Get favorite status as a stream
  Stream<bool> getFavoriteStatusStream(String sellerId) {
    if (_currentUserId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('favorites')
        .doc('${_currentUserId}_$sellerId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get all favorited sellers
  Stream<List<String>> getFavoritedSellers() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('favorites')
        .where('user_id', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['seller_id'] as String)
          .toList();
    });
  }

  /// Get all users who favorited a seller
  Future<List<String>> getUsersWhoFavorited(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('seller_id', isEqualTo: sellerId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['user_id'] as String)
          .toList();
    } catch (e) {
      print('Error getting users who favorited: $e');
      return [];
    }
  }

  /// Notify all users who favorited this seller about a new listing
  Future<void> notifyFavoritesOnNewListing({
    required String sellerId,
    required String listingId,
    required String listingTitle,
    String? listingImage,
  }) async {
    try {
      // Get seller's info
      final sellerDoc =
          await _firestore.collection('users').doc(sellerId).get();
      final sellerName = sellerDoc.data()?['fullName'] ??
          sellerDoc.data()?['full_name'] ??
          'A seller';

      // Get all users who favorited this seller
      final favoritedUsers = await getUsersWhoFavorited(sellerId);

      // Send notification to each user
      for (final userId in favoritedUsers) {
        await _firestore.collection('notifications').add({
          'recipient_id': userId,
          'sender_id': sellerId,
          'sender_name': sellerName,
          'sender_profile_image': sellerDoc.data()?['profileImageUrl'],
          'type': 'new_listing',
          'title': 'New Listing',
          'body': '$sellerName posted "$listingTitle"',
          'related_listing_id': listingId,
          'related_user_id': sellerId,
          'is_read': false,
          'created_at': FieldValue.serverTimestamp(),
          'additional_data': {
            'listing_id': listingId,
            'listing_image': listingImage,
            'listing_title': listingTitle,
          },
        });
      }

      print('Notified ${favoritedUsers.length} users about new listing');
    } catch (e) {
      print('Error notifying favorites: $e');
    }
  }

  /// Get count of users who favorited a seller
  Future<int> getFavoritesCount(String sellerId) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('seller_id', isEqualTo: sellerId)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  /// Get favorites count as a stream
  Stream<int> getFavoritesCountStream(String sellerId) {
    return _firestore
        .collection('favorites')
        .where('seller_id', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Map<String, dynamic>>> getFollowingProfiles(String userId) {
    return _firestore
        .collection('favorites')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        String sellerId = doc.data()['seller_id'];
        var userDoc = await _firestore.collection('users').doc(sellerId).get();
        if (userDoc.exists) {
          var data = userDoc.data()!;
          data['uid'] = userDoc.id; // Ensure the ID is attached
          users.add(data);
        }
      }
      return users;
    });
  }

  /// Get actual user profiles of everyone following this user
  Stream<List<Map<String, dynamic>>> getFollowersProfiles(String userId) {
    return _firestore
        .collection('favorites')
        .where('seller_id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> users = [];
      for (var doc in snapshot.docs) {
        String followerId = doc.data()['user_id'];
        var userDoc =
            await _firestore.collection('users').doc(followerId).get();
        if (userDoc.exists) {
          var data = userDoc.data()!;
          data['uid'] = userDoc.id;
          users.add(data);
        }
      }
      return users;
    });
  }
}
