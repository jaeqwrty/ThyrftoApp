import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/core/services/notification_service.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<Map<String, dynamic>?> watchTransactionForOffer(String offerId) {
    if (offerId.isEmpty) return Stream.value(null);
    return _firestore.collection('transactions').doc(offerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return <String, dynamic>{...doc.data()!, 'id': doc.id};
    });
  }

  /// Confirms that the in-person/off-app exchange has actually completed.
  /// The listing becomes sold only after both buyer and seller confirm.
  ///
  /// For reservations created before transaction records existed, the first
  /// participant confirmation also backfills the deterministic transaction.
  Future<Map<String, dynamic>> confirmCompletionForOffer(String offerId) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('User not authenticated');
    if (offerId.isEmpty) throw ArgumentError('Offer is required');

    final transactionRef = _firestore.collection('transactions').doc(offerId);

    late String buyerId;
    late String sellerId;
    late String listingId;
    late String chatId;
    late String listingTitle;
    late String role;
    var changed = false;
    var completed = false;
    var alreadyConfirmed = false;

    await _firestore.runTransaction((transaction) async {
      final transactionSnapshot = await transaction.get(transactionRef);
      Map<String, dynamic> data;
      var isBackfill = false;

      if (transactionSnapshot.exists) {
        data = transactionSnapshot.data()!;
      } else {
        final offerRef = _firestore.collection('offers').doc(offerId);
        final offerSnapshot = await transaction.get(offerRef);
        if (!offerSnapshot.exists) {
          throw StateError('The accepted offer no longer exists');
        }

        final offer = offerSnapshot.data()!;
        if (offer['status'] != 'accepted') {
          throw StateError('Only an accepted offer can be completed');
        }

        final offerListingId = offer['listing_id']?.toString();
        if (offerListingId == null || offerListingId.isEmpty) {
          throw StateError('The listing for this transaction is unavailable');
        }

        final listingSnapshot = await transaction.get(
          _firestore.collection('listings').doc(offerListingId),
        );
        final listing = listingSnapshot.data();
        if (!listingSnapshot.exists ||
            listing?['status'] != 'reserved' ||
            listing?['reserved_offer_id'] != offerId ||
            listing?['reserved_for_user_id'] != offer['buyer_id']) {
          throw StateError('This reservation is no longer active');
        }

        data = {
          'offer_id': offerId,
          'listing_id': offerListingId,
          'listing_title': offer['listing_title']?.toString() ??
              listing?['title']?.toString() ??
              'Listing',
          'seller_id': offer['seller_id'],
          'buyer_id': offer['buyer_id'],
          'chat_id': offer['chat_id'],
          'agreed_price': (offer['amount'] as num?)?.toDouble() ?? 0,
          'status': 'reserved',
          'buyer_confirmed': false,
          'seller_confirmed': false,
        };
        isBackfill = true;
      }

      buyerId = data['buyer_id']?.toString() ?? '';
      sellerId = data['seller_id']?.toString() ?? '';
      listingId = data['listing_id']?.toString() ?? '';
      chatId = data['chat_id']?.toString() ?? '';
      listingTitle = data['listing_title']?.toString() ?? 'Listing';

      if (buyerId.isEmpty || sellerId.isEmpty || listingId.isEmpty || chatId.isEmpty) {
        throw StateError('Transaction information is incomplete');
      }
      if (userId != buyerId && userId != sellerId) {
        throw StateError('You are not part of this transaction');
      }

      role = userId == buyerId ? 'buyer' : 'seller';
      final status = data['status']?.toString() ?? 'reserved';
      if (status == 'completed') {
        completed = true;
        alreadyConfirmed = true;
        return;
      }
      if (status != 'reserved') {
        throw StateError('This transaction can no longer be completed');
      }

      final buyerConfirmed = data['buyer_confirmed'] == true;
      final sellerConfirmed = data['seller_confirmed'] == true;
      final userAlreadyConfirmed =
          role == 'buyer' ? buyerConfirmed : sellerConfirmed;
      if (userAlreadyConfirmed) {
        alreadyConfirmed = true;
        completed = buyerConfirmed && sellerConfirmed;
        return;
      }

      final nextBuyerConfirmed = buyerConfirmed || role == 'buyer';
      final nextSellerConfirmed = sellerConfirmed || role == 'seller';
      completed = nextBuyerConfirmed && nextSellerConfirmed;
      changed = true;

      DocumentReference<Map<String, dynamic>>? completedListingRef;
      if (completed) {
        completedListingRef =
            _firestore.collection('listings').doc(listingId);
        final listingSnapshot = await transaction.get(completedListingRef);
        final listing = listingSnapshot.data();
        if (!listingSnapshot.exists ||
            listing?['status'] != 'reserved' ||
            listing?['reserved_offer_id'] != offerId ||
            listing?['reserved_for_user_id'] != buyerId) {
          throw StateError('This reservation is no longer active');
        }
      }

      final updateData = <String, dynamic>{
        'buyer_confirmed': nextBuyerConfirmed,
        'seller_confirmed': nextSellerConfirmed,
        'status': completed ? 'completed' : 'reserved',
        'updated_at': FieldValue.serverTimestamp(),
        'last_action_by': userId,
        if (role == 'buyer')
          'buyer_confirmed_at': FieldValue.serverTimestamp(),
        if (role == 'seller')
          'seller_confirmed_at': FieldValue.serverTimestamp(),
        if (completed) 'completed_at': FieldValue.serverTimestamp(),
      };

      if (isBackfill) {
        transaction.set(transactionRef, {
          ...data,
          ...updateData,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(transactionRef, updateData);
      }

      if (completed && completedListingRef != null) {
        transaction.update(completedListingRef, {
          'status': 'sold',
          'sold_transaction_id': offerId,
          'sold_at': FieldValue.serverTimestamp(),
          'reserved_for_user_id': FieldValue.delete(),
          'reserved_offer_id': FieldValue.delete(),
          'reserved_at': FieldValue.delete(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();
      transaction.set(messageRef, {
        'senderId': userId,
        'transactionId': offerId,
        'listingId': listingId,
        'transactionStatus': completed ? 'completed' : 'reserved',
        'confirmedRole': role,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'transaction_update',
      });
      transaction.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': completed
            ? 'Transaction completed'
            : '${role == 'buyer' ? 'Buyer' : 'Seller'} confirmed the exchange',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'deletedFor': FieldValue.arrayRemove([buyerId, sellerId]),
      });
    });

    if (changed) {
      final recipientId = userId == buyerId ? sellerId : buyerId;
      try {
        await _notificationService.createNotification(
          recipientId: recipientId,
          type: 'transaction',
          title: completed
              ? 'Transaction completed'
              : '${role == 'buyer' ? 'Buyer' : 'Seller'} confirmed the exchange',
          body: completed
              ? '$listingTitle is now marked sold.'
              : 'Confirm the exchange for $listingTitle when it is complete on your side.',
          relatedListingId: listingId,
          relatedUserId: userId,
          additionalData: {
            'transaction_id': offerId,
            'transaction_status': completed ? 'completed' : 'reserved',
            'chat_id': chatId,
            'confirmed_role': role,
          },
        );
      } catch (_) {
        // Transaction state is authoritative; notification delivery is best-effort.
      }
    }

    return {
      'changed': changed,
      'completed': completed,
      'already_confirmed': alreadyConfirmed,
      'role': role,
    };
  }
}
