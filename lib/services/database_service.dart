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

      // Upload new images if any
      List<String> allImageUrls = List.from(existingImageUrls);
      if (newImageFiles.isNotEmpty) {
        final newUrls = await uploadImages(newImageFiles, listingId);
        allImageUrls.addAll(newUrls);
      }

      // Update listing data
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

      // Sort client-side to avoid requiring composite index
      listings.sort((a, b) {
        final aTime = a['created_at']?.toDate() ?? DateTime(2000);
        final bTime = b['created_at']?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime); // Descending
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

      // Get listing document to find seller
      final listingDoc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listingData = listingDoc.data()!;
      final sellerId = listingData['seller_id'];
      final listingTitle = listingData['title'] ?? 'a listing';

      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await _firestore.collection('listings').doc(listingId).update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'userId': currentUserId,
          'listingId': listingId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('listings').doc(listingId).update({
          'likes': FieldValue.increment(1),
        });

        // Send notification only if seller is different from liker
        if (sellerId != null && sellerId != currentUserId) {
          await _createNotification(
            recipientId: sellerId,
            type: 'like',
            title: 'Someone liked your listing',
            body: 'Your listing "$listingTitle" received a like',
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

  // Get or create chat
  Future<String?> getOrCreateChat(String otherUserId) async {
    if (currentUserId == null) return null;

    try {
      // Check if chat already exists
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

      // Create new chat
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
      // Delete images from storage
      await deleteListingImages(listingId);

      // Delete listing document
      await _firestore.collection('listings').doc(listingId).delete();

      // Delete related likes
      final likes = await _firestore
          .collection('likes')
          .where('listingId', isEqualTo: listingId)
          .get();

      for (var doc in likes.docs) {
        await doc.reference.delete();
      }

      // Delete related bookmarks
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

      // Sort client-side to avoid requiring composite index
      listings.sort((a, b) {
        final aTime = a['created_at']?.toDate() ?? DateTime(2000);
        final bTime = b['created_at']?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime); // Descending
      });

      return listings;
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
        SettableMetadata(
          contentType: _getContentType(imageFile.name),
        ),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Add a comment to a listing
  Future<void> addCommentWithNotification({
    required String listingId,
    required String userId,
    required String userName,
    required String comment,
  }) async {
    try {
      // Get user's profile image
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userProfileImage = userDoc.data()?['profileImageUrl'] as String?;

      // Get listing info to find seller
      final listingDoc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listingData = listingDoc.data()!;
      final sellerId = listingData['seller_id'];

      // Add comment
      await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .add({
        'user_id': userId,
        'user_name': userName,
        'user_profile_image': userProfileImage,
        'comment': comment,
        'created_at': FieldValue.serverTimestamp(),
        'reply_count': 0,
      });

      // Update comment count
      await _firestore.collection('listings').doc(listingId).update({
        'comments_count': FieldValue.increment(1),
      });

      // Send notification only if commenter is not the seller
      if (sellerId != null && sellerId != userId) {
        await _createNotification(
          recipientId: sellerId,
          type: 'comment',
          title: '$userName commented on your listing',
          body: 'Comment: "$comment"',
          relatedListingId: listingId,
          relatedUserId: userId,
        );
      }
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a listing WITH replies
  Stream<List<Map<String, dynamic>>> getComments(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .collection('comments')
        .orderBy('created_at', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> comments = [];

      for (var doc in snapshot.docs) {
        final commentData = doc.data();
        commentData['id'] = doc.id;

        // Fetch replies for this comment
        final repliesSnapshot = await _firestore
            .collection('listings')
            .doc(listingId)
            .collection('comments')
            .doc(doc.id)
            .collection('replies')
            .orderBy('created_at', descending: false)
            .get();

        commentData['replies'] = repliesSnapshot.docs.map((replyDoc) {
          final replyData = replyDoc.data();
          replyData['id'] = replyDoc.id;
          return replyData;
        }).toList();

        comments.add(commentData);
      }

      return comments;
    });
  }

  /// Delete a comment and all its replies
  Future<void> deleteComment(String listingId, String commentId) async {
    try {
      // Delete all replies first
      final repliesSnapshot = await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .get();

      for (var replyDoc in repliesSnapshot.docs) {
        await replyDoc.reference.delete();
      }

      // Delete the comment
      await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Update comment count on listing
      await _firestore.collection('listings').doc(listingId).update({
        'comments_count': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  Future<void> addReply({
    required String listingId,
    required String commentId,
    required String userId,
    required String userName,
    required String reply,
  }) async {
    try {
      // Add reply to the comment's replies subcollection
      await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add({
        'user_id': userId,
        'user_name': userName,
        'reply': reply,
        'created_at': FieldValue.serverTimestamp(),
      });

      // Update reply count on the comment
      await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .doc(commentId)
          .update({
        'reply_count': FieldValue.increment(1),
      });

      // Get comment info for notification
      final commentDoc = await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .doc(commentId)
          .get();

      if (commentDoc.exists) {
        final commentData = commentDoc.data()!;
        final commentOwnerId = commentData['user_id'];

        // Send notification to comment owner if replier is not the comment owner
        if (commentOwnerId != null && commentOwnerId != userId) {
          await _createNotification(
            recipientId: commentOwnerId,
            type: 'reply',
            title: '$userName replied to your comment',
            body: 'Reply: "$reply"',
            relatedListingId: listingId,
            relatedUserId: userId,
          );
        }
      }
    } catch (e) {
      print('Error adding reply: $e');
      throw Exception('Failed to add reply: $e');
    }
  }

  /// Delete a reply
  Future<void> deleteReply(
      String listingId, String commentId, String replyId) async {
    try {
      await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId)
          .delete();

      // Update reply count on the comment
      await _firestore
          .collection('listings')
          .doc(listingId)
          .collection('comments')
          .doc(commentId)
          .update({
        'reply_count': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to delete reply: $e');
    }
  }

  // Get comment count for a listing
  Future<int> getCommentCount(String listingId) async {
    try {
      final doc = await _firestore.collection('listings').doc(listingId).get();
      return doc.data()?['comments_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get comment count as a stream
  Stream<int> getCommentCountStream(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((doc) => doc.data()?['comments_count'] ?? 0);
  }

  Stream<bool> isListingLikedStream(String listingId) {
    if (currentUserId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('likes')
        .doc('${currentUserId}_$listingId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Stream to check if listing is bookmarked (real-time)
  Stream<bool> isListingBookmarkedStream(String listingId) {
    if (currentUserId == null) {
      return Stream.value(false);
    }

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

  // IMPORTANT: Replace the existing getBookmarkedListings in database_service.dart with this:
  // Get user's bookmarked listings with real-time updates and proper ordering
  Stream<List<Map<String, dynamic>>> getBookmarkedListingsUpdated() {
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
          data['bookmarked_at'] = doc.data()['createdAt'];
          listings.add(data);
        }
      }

      // Sort by bookmark date (most recent first)
      listings.sort((a, b) {
        final aTime = a['bookmarked_at']?.toDate() ?? DateTime(2000);
        final bTime = b['bookmarked_at']?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return listings;
    });
  }
  // Add these methods to your DatabaseService class

  /// Increment the share count for a listing
  Future<void> incrementShareCount(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'shares': FieldValue.increment(1),
      });
      print('Share count incremented for listing: $listingId');
    } catch (e) {
      print('Error incrementing share count: $e');
      rethrow;
    }
  }

  /// Get the share count for a listing as a stream (real-time updates)
  Stream<int> getShareCountStream(String listingId) {
    try {
      return _firestore
          .collection('listings')
          .doc(listingId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) return 0;
        final data = snapshot.data() ?? {};
        final shares = data['shares'];

        // Handle both int and double types
        if (shares is int) {
          return shares;
        } else if (shares is double) {
          return shares.toInt();
        }
        return 0;
      }).handleError((error) {
        print('Error in getShareCountStream: $error');
        return 0;
      });
    } catch (e) {
      print('Error creating share count stream: $e');
      return Stream.value(0);
    }
  }

  /// Get the share count for a listing (single fetch)
  Future<int> getShareCount(String listingId) async {
    try {
      final snapshot =
          await _firestore.collection('listings').doc(listingId).get();
      if (!snapshot.exists) return 0;

      final data = snapshot.data() ?? {};
      final shares = data['shares'];

      // Handle both int and double types
      if (shares is int) {
        return shares;
      } else if (shares is double) {
        return shares.toInt();
      }
      return 0;
    } catch (e) {
      print('Error getting share count: $e');
      return 0;
    }
  }

  /// Call this method when user shares a listing
  Future<void> onListingSharedWithNotification(String listingId) async {
    try {
      // Get listing info
      final listingDoc =
          await _firestore.collection('listings').doc(listingId).get();

      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listingData = listingDoc.data()!;
      final sellerId = listingData['seller_id'];
      final listingTitle = listingData['title'] ?? 'a listing';

      // Increment share count
      await incrementShareCount(listingId);

      // Track the share
      await _firestore.collection('listing_shares').add({
        'listing_id': listingId,
        'shared_by': currentUserId,
        'shared_at': FieldValue.serverTimestamp(),
      });

      // Send notification only if sharer is not the seller
      if (sellerId != null && sellerId != currentUserId) {
        await _createNotification(
          recipientId: sellerId,
          type: 'share',
          title: 'Someone shared your listing',
          body: 'Your listing "$listingTitle" was shared',
          relatedListingId: listingId,
          relatedUserId: currentUserId,
        );
      }

      print('Listing shared and tracked: $listingId');
    } catch (e) {
      print('Error tracking share: $e');
      rethrow;
    }
  }

  Future<void> sendMessageWithNotification({
    required String recipientId,
    required String messageText,
  }) async {
    try {
      if (currentUserId == null) return;

      await _createNotification(
        recipientId: recipientId,
        type: 'message',
        title: 'You received a new message',
        body: messageText.length > 50
            ? '${messageText.substring(0, 50)}...'
            : messageText,
        relatedUserId: currentUserId,
      );
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }

  /// Internal helper: Create notification in Firestore
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
      await _firestore.collection('notifications').add({
        'recipient_id': recipientId,
        'sender_id': currentUserId,
        'type': type,
        'title': title,
        'body': body,
        'related_listing_id': relatedListingId,
        'related_user_id': relatedUserId,
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'additional_data': additionalData ?? {},
      });
      print('Notification created: $title');
    } catch (e) {
      print('Error creating notification: $e');
      rethrow;
    }
  }

  /// Delete a chat conversation and all its messages
  Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages in the chat
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (var doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the chat document
      await _firestore.collection('chats').doc(chatId).delete();

      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }

  /// Delete a specific message from a chat
  Future<bool> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Update last message if needed
      final remainingMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (remainingMessages.docs.isEmpty) {
        // No messages left, update chat
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      } else {
        // Update with the latest message
        final lastMsg = remainingMessages.docs.first.data();
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': lastMsg['text'] ?? '',
          'lastMessageTime':
              lastMsg['timestamp'] ?? FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }
}
