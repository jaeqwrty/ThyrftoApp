import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Upload images to Firebase Storage
  Future<List<String>> uploadImages(
    List<XFile> imageFiles,
    String listingId,
  ) async {
    List<String> imageUrls = [];

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileName = '${listingId}_$i${path.extension(file.path)}';
        final storageRef =
            _storage.ref().child('listings/$listingId/$fileName');

        // Upload file
        final bytes = await file.readAsBytes();
        final uploadTask = await storageRef.putData(
          bytes,
          SettableMetadata(
            contentType: _getContentType(file.name),
          ),
        );

        // Get download URL
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      throw Exception('Failed to upload images: $e');
    }
  }

  // Get content type based on file extension
  String _getContentType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  // Create a new listing with image upload
  Future<Map<String, dynamic>> createListing({
    required String userId,
    required String title,
    required String description,
    required double price,
    required String size,
    required String condition,
    required String category,
    required List<XFile> imageFiles,
    Map<String, dynamic>? location,
  }) async {
    try {
      if (imageFiles.isEmpty) {
        return {
          'success': false,
          'message': 'At least one image is required',
        };
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      final listingRef = _firestore.collection('listings').doc();
      final listingId = listingRef.id;

      final imageUrls = await uploadImages(imageFiles, listingId);

      final listingData = {
        'id': listingId,
        'seller_id': userId,
        'seller_name':
            userData['full_name'] ?? userData['username'] ?? 'Unknown',
        'seller_location': userData['cityState'] ?? 'Location not available',
        'title': title,
        'description': description,
        'price': price,
        'size': size,
        'condition': condition,
        'category': category,
        'image_urls': imageUrls,
        'status': 'active',
        'likes': 0,
        'views': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'location': location,
      };

      await listingRef.set(listingData);

      return {
        'success': true,
        'message': 'Listing created successfully',
        'listingId': listingId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create listing: $e',
      };
    }
  }

  // Update an existing listing
  Future<Map<String, dynamic>> updateListing({
    required String listingId,
    required String title,
    required double price,
    required String description,
    required String category,
    required String size,
    required String condition,
    required List<String> existingImageUrls,
    required List<XFile> newImageFiles,
  }) async {
    try {
      if (existingImageUrls.isEmpty && newImageFiles.isEmpty) {
        return {
          'success': false,
          'message': 'At least one image is required',
        };
      }

      List<String> allImageUrls = List.from(existingImageUrls);
      if (newImageFiles.isNotEmpty) {
        final newUrls = await uploadImages(newImageFiles, listingId);
        allImageUrls.addAll(newUrls);
      }

      await _firestore.collection('listings').doc(listingId).update({
        'title': title,
        'price': price,
        'description': description,
        'category': category,
        'size': size,
        'condition': condition,
        'image_urls': allImageUrls,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Listing updated successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update listing: $e',
      };
    }
  }

  // Get active listings stream
  Stream<List<Map<String, dynamic>>> getActiveListings() {
    return _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      listings.sort((a, b) {
        final aTime = a['created_at']?.toDate() ?? DateTime(2000);
        final bTime = b['created_at']?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return listings;
    });
  }

  // Get user profile
  Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    });
  }

  // Toggle like
  Future<void> toggleLikeWithNotification(String listingId) async {
    if (currentUserId == null) return;

    try {
      final likeRef =
          _firestore.collection('likes').doc('${currentUserId}_$listingId');
      final likeDoc = await likeRef.get();

      final listingDoc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listingData = listingDoc.data()!;
      final sellerId = listingData['seller_id'];
      final listingTitle = listingData['title'] ?? 'a listing';

      if (likeDoc.exists) {
        await likeRef.delete();
        await _firestore.collection('listings').doc(listingId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        await likeRef.set({
          'userId': currentUserId,
          'listingId': listingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('listings').doc(listingId).update({
          'likes': FieldValue.increment(1),
        });

        if (sellerId != null && sellerId != currentUserId) {
          final currentUserDoc =
              await _firestore.collection('users').doc(currentUserId).get();
          final currentUserName = currentUserDoc.data()?['fullName'] ??
              currentUserDoc.data()?['full_name'] ??
              currentUserDoc.data()?['username'] ??
              'Someone';

          await _createNotification(
            recipientId: sellerId,
            type: 'like',
            title: '$currentUserName liked your listing',
            body: '"$listingTitle"',
            relatedListingId: listingId,
            relatedUserId: currentUserId,
          );
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Check if listing is liked
  Future<bool> isListingLiked(String listingId) async {
    if (currentUserId == null) return false;
    try {
      final likeDoc = await _firestore
          .collection('likes')
          .doc('${currentUserId}_$listingId')
          .get();
      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Toggle bookmark
  Future<void> toggleBookmark(String listingId) async {
    if (currentUserId == null) return;
    try {
      final bookmarkRef =
          _firestore.collection('bookmarks').doc('${currentUserId}_$listingId');
      final bookmarkDoc = await bookmarkRef.get();
      if (bookmarkDoc.exists) {
        await bookmarkRef.delete();
      } else {
        await bookmarkRef.set({
          'userId': currentUserId,
          'listingId': listingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  // Check if listing is bookmarked
  Future<bool> isListingBookmarked(String listingId) async {
    if (currentUserId == null) return false;
    try {
      final bookmarkDoc = await _firestore
          .collection('bookmarks')
          .doc('${currentUserId}_$listingId')
          .get();
      return bookmarkDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Delete listing images
  Future<void> deleteListingImages(String listingId) async {
    try {
      final listingFolder = _storage.ref().child('listings/$listingId');
      final listResult = await listingFolder.listAll();
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {}
  }

  // Delete listing
  Future<bool> deleteListing(String listingId) async {
    try {
      await deleteListingImages(listingId);
      await _firestore.collection('listings').doc(listingId).delete();
      final likes = await _firestore
          .collection('likes')
          .where('listingId', isEqualTo: listingId)
          .get();
      for (var doc in likes.docs) {
        await doc.reference.delete();
      }
      final bookmarks = await _firestore
          .collection('bookmarks')
          .where('listingId', isEqualTo: listingId)
          .get();
      for (var doc in bookmarks.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user's listings
  Stream<List<Map<String, dynamic>>> getUserListings(String userId) {
    return _firestore
        .collection('listings')
        .where('seller_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      listings.sort((a, b) {
        final aTime = a['created_at']?.toDate() ?? DateTime(2000);
        final bTime = b['created_at']?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return listings;
    });
  }

  // Get user's bookmarked listings
  Stream<List<Map<String, dynamic>>> getBookmarkedListings() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('bookmarks')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> listings = [];
      for (var doc in snapshot.docs) {
        final listingId = doc.data()['listingId'];
        final listingDoc =
            await _firestore.collection('listings').doc(listingId).get();
        if (listingDoc.exists) {
          final data = listingDoc.data()!;
          data['id'] = listingDoc.id;
          listings.add(data);
        }
      }
      return listings;
    });
  }

  // Upload profile image
  Future<String?> uploadProfileImage(XFile imageFile, String userId) async {
    try {
      final ext = path.extension(imageFile.name).isEmpty
          ? '.jpg'
          : path.extension(imageFile.name);
      final fileName = 'profile_$userId$ext';
      final storageRef = _storage.ref().child('profiles/$userId/$fileName');
      final bytes = await imageFile.readAsBytes();
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: _getContentType(imageFile.name)),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // --- Real-time Streams ---

  Stream<bool> isListingLikedStream(String listingId) {
    if (currentUserId == null) return Stream.value(false);
    return _firestore
        .collection('likes')
        .doc('${currentUserId}_$listingId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<bool> isListingBookmarkedStream(String listingId) {
    if (currentUserId == null) return Stream.value(false);
    return _firestore
        .collection('bookmarks')
        .doc('${currentUserId}_$listingId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<Map<String, dynamic>?> getListingStream(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    });
  }

  Stream<List<Map<String, dynamic>>> getBookmarkedListingsUpdated() {
    if (currentUserId == null) return Stream.value([]);
    return _firestore
        .collection('bookmarks')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> listings = [];
      for (var doc in snapshot.docs) {
        final listingId = doc.data()['listingId'];
        final listingDoc =
            await _firestore.collection('listings').doc(listingId).get();
        if (listingDoc.exists) {
          final data = listingDoc.data()!;
          data['id'] = listingDoc.id;
          data['bookmarked_at'] = doc.data()['createdAt'];
          listings.add(data);
        }
      }
      listings.sort((a, b) {
        final aTime = a['bookmarked_at']?.toDate() ?? DateTime(2000);
        final bTime = b['bookmarked_at']?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      return listings;
    });
  }

  // --- Share Logic ---

  Future<void> incrementShareCount(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'shares': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing share count: $e');
      rethrow;
    }
  }

  Stream<int> getShareCountStream(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return 0;
      final shares = snapshot.data()?['shares'];
      return shares is int ? shares : (shares as double?)?.toInt() ?? 0;
    }).handleError((_) => 0);
  }

  Future<int> getShareCount(String listingId) async {
    try {
      final snapshot =
          await _firestore.collection('listings').doc(listingId).get();
      if (!snapshot.exists) return 0;
      final shares = snapshot.data()?['shares'];
      return shares is int ? shares : (shares as double?)?.toInt() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> onListingSharedWithNotification(String listingId) async {
    try {
      final listingDoc =
          await _firestore.collection('listings').doc(listingId).get();
      if (!listingDoc.exists) throw Exception('Listing not found');

      final sellerId = listingDoc.data()?['seller_id'];
      final listingTitle = listingDoc.data()?['title'] ?? 'a listing';

      await incrementShareCount(listingId);
      await _firestore.collection('listing_shares').add({
        'listing_id': listingId,
        'shared_by': currentUserId,
        'shared_at': FieldValue.serverTimestamp(),
      });

      if (sellerId != null && sellerId != currentUserId) {
        final currentUserDoc =
            await _firestore.collection('users').doc(currentUserId!).get();
        final currentUserName = currentUserDoc.data()?['fullName'] ??
            currentUserDoc.data()?['full_name'] ??
            currentUserDoc.data()?['username'] ??
            'Someone';

        await _createNotification(
          recipientId: sellerId,
          type: 'share',
          title: '$currentUserName shared your listing',
          body: '"$listingTitle"',
          relatedListingId: listingId,
          relatedUserId: currentUserId,
        );
      }
    } catch (e) {
      print('Error tracking share: $e');
      rethrow;
    }
  }

  // --- Internal Helper ---

  Future<void> _createNotification({
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? relatedListingId,
    String? relatedUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String senderName = 'Someone';
      String? senderProfileImage;

      if (currentUserId != null) {
        final senderDoc =
            await _firestore.collection('users').doc(currentUserId).get();
        if (senderDoc.exists) {
          final senderData = senderDoc.data()!;
          senderName = senderData['fullName'] ??
              senderData['full_name'] ??
              senderData['username'] ??
              'Someone';
          senderProfileImage = senderData['profileImageUrl'] as String?;
        }
      }

      await _firestore.collection('notifications').add({
        'recipient_id': recipientId,
        'sender_id': currentUserId,
        'sender_name': senderName,
        'sender_profile_image': senderProfileImage,
        'type': type,
        'title': title,
        'body': body,
        'related_listing_id': relatedListingId,
        'related_user_id': relatedUserId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'additional_data': additionalData ?? {},
      });
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }
}