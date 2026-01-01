import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Block a user
  Future<bool> blockUser(String userId) async {
    if (currentUserId == null || userId == currentUserId) {
      print('BlockService: Cannot block - invalid user IDs');
      return false;
    }

    try {
      print('BlockService: Starting block process for user: $userId');

      // Create a block document with a batch write for atomicity
      final batch = _firestore.batch();

      // Add block document
      final blockRef =
          _firestore.collection('blocks').doc('${currentUserId}_$userId');
      batch.set(blockRef, {
        'blocker_id': currentUserId,
        'blocked_id': userId,
        'blocked_at': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();
      print('BlockService: Block document created successfully');

      // Remove from favorites if following (separate operation)
      try {
        final favoriteRef =
            _firestore.collection('favorites').doc('${currentUserId}_$userId');

        final favoriteDoc = await favoriteRef.get();
        if (favoriteDoc.exists) {
          await favoriteRef.delete();
          print('BlockService: Removed from favorites');
        }
      } catch (e) {
        print('BlockService: Error removing favorite (non-critical): $e');
      }

      // Delete active chats between users (separate operation)
      try {
        final chatsSnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .get();

        for (var chatDoc in chatsSnapshot.docs) {
          final participants =
              List<String>.from(chatDoc.data()['participants'] ?? []);
          if (participants.contains(userId)) {
            await chatDoc.reference.delete();
            print('BlockService: Deleted chat: ${chatDoc.id}');
          }
        }
      } catch (e) {
        print('BlockService: Error deleting chats (non-critical): $e');
      }

      print('BlockService: User blocked successfully: $userId');
      return true;
    } catch (e) {
      print('BlockService: Error blocking user: $e');
      print('BlockService: Error details: ${e.toString()}');
      return false;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    if (currentUserId == null) {
      print('BlockService: Cannot unblock - no current user');
      return false;
    }

    try {
      print('BlockService: Unblocking user: $userId');

      await _firestore
          .collection('blocks')
          .doc('${currentUserId}_$userId')
          .delete();

      print('BlockService: User unblocked successfully: $userId');
      return true;
    } catch (e) {
      print('BlockService: Error unblocking user: $e');
      return false;
    }
  }

  /// Check if a user is blocked by current user
  Future<bool> isUserBlocked(String userId) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('blocks')
          .doc('${currentUserId}_$userId')
          .get();

      return doc.exists;
    } catch (e) {
      print('BlockService: Error checking block status: $e');
      return false;
    }
  }

  /// Check if current user is blocked by another user
  Future<bool> isBlockedBy(String userId) async {
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('blocks')
          .doc('${userId}_$currentUserId')
          .get();

      return doc.exists;
    } catch (e) {
      print('BlockService: Error checking if blocked by user: $e');
      return false;
    }
  }

  /// Stream to check if user is blocked (real-time)
  Stream<bool> isUserBlockedStream(String userId) {
    if (currentUserId == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('blocks')
        .doc('${currentUserId}_$userId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get all blocked users as a stream
  Stream<List<Map<String, dynamic>>> getBlockedUsersStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('blocks')
        .where('blocker_id', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> blockedUsers = [];

      for (var doc in snapshot.docs) {
        final blockData = doc.data();
        final blockedUserId = blockData['blocked_id'];

        if (blockedUserId == null) continue;

        try {
          // Fetch user details
          final userDoc =
              await _firestore.collection('users').doc(blockedUserId).get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            userData['id'] = userDoc.id;
            userData['blocked_at'] = blockData['blocked_at'];
            blockedUsers.add(userData);
          }
        } catch (e) {
          print('BlockService: Error fetching user $blockedUserId: $e');
        }
      }

      // Sort by blocked_at (most recent first)
      blockedUsers.sort((a, b) {
        final aTime = a['blocked_at']?.toDate() ?? DateTime(2000);
        final bTime = b['blocked_at']?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      return blockedUsers;
    });
  }

  /// Get count of blocked users
  Stream<int> getBlockedUsersCountStream() {
    if (currentUserId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('blocks')
        .where('blocker_id', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Filter out blocked users from a list
  Future<List<Map<String, dynamic>>> filterBlockedUsers(
    List<Map<String, dynamic>> users,
  ) async {
    if (currentUserId == null) return users;

    try {
      // Get all blocks where current user is blocker or blocked
      final blocksSnapshot = await _firestore
          .collection('blocks')
          .where('blocker_id', isEqualTo: currentUserId)
          .get();

      final blockedBySnapshot = await _firestore
          .collection('blocks')
          .where('blocked_id', isEqualTo: currentUserId)
          .get();

      final blockedUserIds = blocksSnapshot.docs
          .map((doc) => doc.data()['blocked_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      final blockedByUserIds = blockedBySnapshot.docs
          .map((doc) => doc.data()['blocker_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // Combine both sets
      final allBlockedUserIds = {...blockedUserIds, ...blockedByUserIds};

      // Filter out blocked users
      return users.where((user) {
        final userId = user['id'] ?? user['uid'];
        return userId != null && !allBlockedUserIds.contains(userId);
      }).toList();
    } catch (e) {
      print('BlockService: Error filtering blocked users: $e');
      return users;
    }
  }

  /// Filter out listings from blocked users
  Future<List<Map<String, dynamic>>> filterBlockedListings(
    List<Map<String, dynamic>> listings,
  ) async {
    if (currentUserId == null) return listings;

    try {
      // Get all blocks where current user is blocker or blocked
      final blocksSnapshot = await _firestore
          .collection('blocks')
          .where('blocker_id', isEqualTo: currentUserId)
          .get();

      final blockedBySnapshot = await _firestore
          .collection('blocks')
          .where('blocked_id', isEqualTo: currentUserId)
          .get();

      final blockedUserIds = blocksSnapshot.docs
          .map((doc) => doc.data()['blocked_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      final blockedByUserIds = blockedBySnapshot.docs
          .map((doc) => doc.data()['blocker_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // Combine both sets
      final allBlockedUserIds = {...blockedUserIds, ...blockedByUserIds};

      // Filter out listings from blocked users
      return listings.where((listing) {
        final sellerId = listing['seller_id'] ?? listing['user_id'];
        return sellerId != null && !allBlockedUserIds.contains(sellerId);
      }).toList();
    } catch (e) {
      print('BlockService: Error filtering blocked listings: $e');
      return listings;
    }
  }

  /// Check if either user has blocked the other
  Future<bool> hasBlockRelationship(String userId) async {
    if (currentUserId == null) return false;

    final blocked = await isUserBlocked(userId);
    final blockedBy = await isBlockedBy(userId);

    return blocked || blockedBy;
  }
}
