import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Upload images to Firebase Storage (supports both web and mobile)
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

        // Upload file - works for both web and mobile
        UploadTask uploadTask;
        
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await file.readAsBytes();
          uploadTask = storageRef.putData(
            bytes,
            SettableMetadata(
              contentType: _getContentType(file.path),
            ),
          );
        } else {
          // For mobile, use file
          uploadTask = storageRef.putFile(
            File(file.path),
            SettableMetadata(
              contentType: _getContentType(file.path),
            ),
          );
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
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
  }) async {
    try {
      if (imageFiles.isEmpty) {
        return {
          'success': false,
          'message': 'At least one image is required',
        };
      }

      // Get user data for seller info
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Create listing document first to get ID
      final listingRef = _firestore.collection('listings').doc();
      final listingId = listingRef.id;

      // Upload images
      final imageUrls = await uploadImages(imageFiles, listingId);

      // Create listing data (using snake_case to match listing_card.dart)
      final listingData = {
        'id': listingId,
        'seller_id': userId,
        'seller_name':
            userData['full_name'] ?? userData['username'] ?? 'Unknown',
        'seller_location': userData['city_state'] ?? '',
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
      };

      // Save to Firestore
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

  // Create a placeholder listing document quickly (no image upload).
  // Returns the listingId or null on failure.
  Future<String?> createListingPlaceholder({
    required String userId,
    required String title,
    required String description,
    required double price,
    required String size,
    required String condition,
    required String category,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      if (userData == null) return null;

      final listingRef = _firestore.collection('listings').doc();
      final listingId = listingRef.id;

      final listingData = {
        'id': listingId,
        'seller_id': userId,
        'seller_name': userData['full_name'] ?? userData['username'] ?? 'Unknown',
        'seller_location': userData['city_state'] ?? '',
        'title': title,
        'description': description,
        'price': price,
        'size': size,
        'condition': condition,
        'category': category,
        'image_urls': <String>[],
        'status': 'uploading',
        'likes': 0,
        'views': 0,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await listingRef.set(listingData);
      return listingId;
    } catch (e) {
      return null;
    }
  }

  // Upload images and finalize the listing document by updating image URLs and status.
  Future<Map<String, dynamic>> finalizeListingUpload({
    required String listingId,
    required List<XFile> imageFiles,
  }) async {
    try {
      if (imageFiles.isEmpty) {
        return {'success': false, 'message': 'No images to upload'};
      }

      final imageUrls = await uploadImages(imageFiles, listingId);

      await _firestore.collection('listings').doc(listingId).update({
        'image_urls': imageUrls,
        'status': 'active',
        'updated_at': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Listing finalized', 'imageUrls': imageUrls};
    } catch (e) {
      // Mark listing as failed
      try {
        await _firestore.collection('listings').doc(listingId).update({
          'status': 'error',
          'updated_at': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      return {'success': false, 'message': 'Failed to upload images: $e'};
    }
  }

  // Get active listings stream - Shows active, uploading, and listings without status
  Stream<List<Map<String, dynamic>>> getActiveListings() {
    return _firestore
        .collection('listings')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Filter to show only active, uploading, or listings without status (old listings)
      final filteredListings = listings.where((listing) {
        final status = listing['status'] as String?;
        return status == null || status == 'active' || status == 'uploading';
      }).toList();
      
      // Sort by created_at manually
      filteredListings.sort((a, b) {
        final aTime = a['created_at'] as Timestamp?;
        final bTime = b['created_at'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      return filteredListings;
    });
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Toggle like
  Future<void> toggleLike(String listingId) async {
    if (currentUserId == null) return;

    try {
      final likeRef =
          _firestore.collection('likes').doc('${currentUserId}_$listingId');

      final likeDoc = await likeRef.get();

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
      }
    } catch (e) {
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

  // Get or create chat
  Future<String?> getOrCreateChat(String otherUserId) async {
    if (currentUserId == null) return null;

    try {
      final existingChat = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      final chatRef = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return chatRef.id;
    } catch (e) {
      return null;
    }
  }

  // Delete listing images from storage
  Future<void> deleteListingImages(String listingId) async {
    try {
      final listingFolder = _storage.ref().child('listings/$listingId');
      final listResult = await listingFolder.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Ignore errors when deleting images
    }
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
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get user's bookmarked listings
  Stream<List<Map<String, dynamic>>> getBookmarkedListings() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

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

  // Upload profile picture to Firebase Storage
  Future<String?> uploadProfilePicture(String userId, XFile imageFile) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final storageRef = _storage.ref().child('profile_pictures/$fileName');

      UploadTask uploadTask;
      
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = storageRef.putFile(
          File(imageFile.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Failed to upload profile picture: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(userId).update(data);
      return true;
    } catch (e) {
      print('Failed to update profile: $e');
      return false;
    }
  }
}