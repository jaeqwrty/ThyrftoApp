import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/core/services/notification_service.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<Map<String, dynamic>?> getOfferStream(String offerId) {
    return _firestore.collection('offers').doc(offerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {...doc.data()!, 'id': doc.id};
    });
  }

  Stream<Map<String, dynamic>?> watchListingState(String listingId) {
    if (listingId.isEmpty) return Stream.value(null);
    return _firestore.collection('listings').doc(listingId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return {...doc.data()!, 'id': doc.id};
    });
  }

  Stream<Map<String, dynamic>?> watchCurrentUserOfferForListing(
    String listingId,
  ) {
    final buyerId = currentUserId;
    if (buyerId == null || listingId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('offers')
        .where('buyer_id', isEqualTo: buyerId)
        .snapshots()
        .map((snapshot) {
      final offers = snapshot.docs
          .where((doc) => doc.data()['listing_id'] == listingId)
          .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
          .toList()
        ..sort((a, b) => _offerTimestampMillis(b)
            .compareTo(_offerTimestampMillis(a)));

      if (offers.isEmpty) return null;

      // Final offers can be followed by a new offer. Any pending, countered,
      // or accepted offer should remain the buyer's visible state.
      for (final offer in offers) {
        final status = offer['status']?.toString();
        if (status != 'declined' && status != 'cancelled') return offer;
      }
      return offers.first;
    });
  }

  Future<String> createOffer({
    required Map<String, dynamic> listing,
    required String chatId,
    required double amount,
  }) async {
    final buyerId = currentUserId;
    final listingId = listing['id']?.toString();
    final sellerId = listing['seller_id']?.toString();
    if (buyerId == null || listingId == null || sellerId == null) {
      throw StateError('Missing offer participants or listing');
    }
    if (buyerId == sellerId) {
      throw StateError('You cannot make an offer on your own listing');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Offer amount must be greater than zero');
    }

    final normalizedAmount = _normalizeMoney(amount);

    final listingDoc =
        await _firestore.collection('listings').doc(listingId).get();
    if (!listingDoc.exists ||
        listingDoc.data()?['seller_id'] != sellerId ||
        listingDoc.data()?['status'] != 'active') {
      throw StateError('This listing is no longer available for offers');
    }

    final currentListing = listingDoc.data()!;
    final title = currentListing['title']?.toString() ?? 'Listing';
    final listingPrice = (currentListing['price'] as num?)?.toDouble() ??
        double.tryParse(currentListing['price']?.toString() ?? '') ??
        0;

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants =
        List<String>.from(chatDoc.data()?['participants'] ?? const <String>[]);
    if (!chatDoc.exists ||
        !participants.contains(buyerId) ||
        !participants.contains(sellerId)) {
      throw StateError('Offer chat is invalid');
    }

    final buyerOffers = await _firestore
        .collection('offers')
        .where('buyer_id', isEqualTo: buyerId)
        .get();
    final hasActiveOffer = buyerOffers.docs.any((doc) {
      final data = doc.data();
      final status = data['status'];
      return data['listing_id'] == listingId &&
          (status == 'pending' ||
              status == 'countered' ||
              status == 'accepted');
    });
    if (hasActiveOffer) {
      throw StateError(
        'You already have an open or accepted offer for this listing',
      );
    }

    final offerRef = _firestore.collection('offers').doc();
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    final batch = _firestore.batch();

    batch.set(offerRef, {
      'listing_id': listingId,
      'listing_title': title,
      'listing_price': listingPrice,
      'seller_id': sellerId,
      'buyer_id': buyerId,
      'chat_id': chatId,
      'initial_amount': normalizedAmount,
      'amount': normalizedAmount,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'last_action_by': buyerId,
    });
    batch.set(messageRef, {
      'senderId': buyerId,
      'offerId': offerRef.id,
      'listingId': listingId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'offer',
    });
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': 'Offer: ${_formatAmount(normalizedAmount)}',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'deletedFor': FieldValue.arrayRemove([buyerId, sellerId]),
    });

    await batch.commit();

    try {
      await _notificationService.createNotification(
        recipientId: sellerId,
        type: 'offer',
        title: 'New offer on $title',
        body: '${_formatAmount(normalizedAmount)} offer received',
        relatedListingId: listingId,
        relatedUserId: buyerId,
        additionalData: {
          'offer_id': offerRef.id,
          'offer_status': 'pending',
          'chat_id': chatId,
        },
      );
    } catch (_) {
      // The offer is already committed; notification delivery is best-effort.
    }

    return offerRef.id;
  }

  Future<void> respondToOffer({
    required String offerId,
    required String action,
    double? counterAmount,
  }) async {
    if (!const {'accepted', 'declined', 'countered'}.contains(action)) {
      throw ArgumentError('Unsupported offer action');
    }
    if (action == 'countered' &&
        (counterAmount == null ||
            !counterAmount.isFinite ||
            counterAmount <= 0)) {
      throw ArgumentError('Counter amount must be greater than zero');
    }

    final userId = currentUserId;
    if (userId == null) throw StateError('User not authenticated');

    final offerRef = _firestore.collection('offers').doc(offerId);
    late Map<String, dynamic> updatedOffer;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(offerRef);
      if (!snapshot.exists) throw StateError('Offer no longer exists');

      final data = snapshot.data()!;
      final sellerId = data['seller_id']?.toString();
      final buyerId = data['buyer_id']?.toString();
      final status = data['status']?.toString();
      final currentAmount = (data['amount'] as num?)?.toDouble() ?? 0;

      final sellerCanRespond =
          userId == sellerId && status == 'pending';
      final buyerCanRespondToCounter =
          userId == buyerId && status == 'countered' && action != 'countered';
      if (!sellerCanRespond && !buyerCanRespondToCounter) {
        throw StateError('This offer can no longer be changed by you');
      }

      DocumentReference<Map<String, dynamic>>? listingRef;
      Map<String, dynamic>? listingData;
      if (action != 'declined') {
        final listingId = data['listing_id']?.toString();
        if (listingId == null) {
          throw StateError('The listing for this offer is unavailable');
        }
        listingRef = _firestore.collection('listings').doc(listingId);
        final listing = await transaction.get(listingRef);
        if (!listing.exists || listing.data()?['status'] != 'active') {
          throw StateError('This listing is no longer available for offers');
        }
        listingData = listing.data();
      }

      final nextAmount = action == 'countered'
          ? _normalizeMoney(counterAmount!)
          : currentAmount;
      transaction.update(offerRef, {
        'amount': nextAmount,
        'status': action,
        'updated_at': FieldValue.serverTimestamp(),
        'last_action_by': userId,
      });

      // Acceptance completes the negotiation and immediately reserves this
      // one-off item for the accepted buyer. Keeping both writes in the same
      // transaction prevents multiple offers from being accepted concurrently.
      if (action == 'accepted' && listingRef != null && listingData != null) {
        final transactionRef =
            _firestore.collection('transactions').doc(offerId);
        transaction.set(transactionRef, {
          'offer_id': offerId,
          'listing_id': data['listing_id'],
          'listing_title': data['listing_title']?.toString() ??
              listingData['title']?.toString() ??
              'Listing',
          'seller_id': sellerId,
          'buyer_id': buyerId,
          'chat_id': data['chat_id'],
          'agreed_price': nextAmount,
          'status': 'reserved',
          'buyer_confirmed': false,
          'seller_confirmed': false,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_action_by': userId,
        });
        transaction.update(listingRef, {
          'status': 'reserved',
          'reserved_for_user_id': buyerId,
          'reserved_offer_id': offerId,
          'reserved_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      final chatId = data['chat_id']?.toString();
      final listingId = data['listing_id']?.toString();
      if (chatId != null && listingId != null) {
        final label = action == 'countered'
            ? 'Counter offer: ${_formatAmount(nextAmount)}'
            : action == 'accepted'
                ? 'Offer accepted'
                : 'Offer declined';
        final updateMessageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        transaction.set(updateMessageRef, {
          'senderId': userId,
          'offerId': offerId,
          'listingId': listingId,
          'offerStatus': action,
          'amount': nextAmount,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'offer_update',
        });
        transaction.update(_firestore.collection('chats').doc(chatId), {
          'lastMessage': label,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'deletedFor': FieldValue.arrayRemove([
            data['buyer_id'],
            data['seller_id'],
          ]),
        });
      }

      updatedOffer = {
        ...data,
        'amount': nextAmount,
        'status': action,
        'last_action_by': userId,
      };
    });

    final sellerId = updatedOffer['seller_id']?.toString();
    final buyerId = updatedOffer['buyer_id']?.toString();
    final recipientId = userId == sellerId ? buyerId : sellerId;
    if (recipientId == null) return;

    final amount = (updatedOffer['amount'] as num?)?.toDouble() ?? 0;
    final title = updatedOffer['listing_title']?.toString() ?? 'listing';
    final status = updatedOffer['status']?.toString() ?? action;
    final notificationTitle = status == 'countered'
        ? 'Counter offer received'
        : status == 'accepted'
            ? 'Offer accepted · Item reserved'
            : 'Offer declined';
    final notificationBody = status == 'countered'
        ? '${_formatAmount(amount)} counter offer on $title'
        : status == 'accepted'
            ? '${_formatAmount(amount)} accepted on $title. The item is now reserved.'
        : '${_formatAmount(amount)} offer on $title';

    try {
      await _notificationService.createNotification(
        recipientId: recipientId,
        type: 'offer',
        title: notificationTitle,
        body: notificationBody,
        relatedListingId: updatedOffer['listing_id']?.toString(),
        relatedUserId: userId,
        additionalData: {
          'offer_id': offerId,
          'offer_status': status,
          'chat_id': updatedOffer['chat_id'],
        },
      );
    } catch (_) {
      // The state transition is already committed; do not invite a retry.
    }
  }

  Future<void> releaseReservationForOffer(String offerId) async {
    final userId = currentUserId;
    if (userId == null) throw StateError('User not authenticated');

    final offerRef = _firestore.collection('offers').doc(offerId);
    late Map<String, dynamic> cancelledOffer;

    await _firestore.runTransaction((transaction) async {
      final offerSnapshot = await transaction.get(offerRef);
      if (!offerSnapshot.exists) throw StateError('Offer no longer exists');

      final offer = offerSnapshot.data()!;
      final sellerId = offer['seller_id']?.toString();
      final buyerId = offer['buyer_id']?.toString();
      final listingId = offer['listing_id']?.toString();
      final chatId = offer['chat_id']?.toString();
      final amount = (offer['amount'] as num?)?.toDouble() ?? 0;

      final isSeller = sellerId == userId;
      final isBuyer = buyerId == userId;
      if ((!isSeller && !isBuyer) || offer['status'] != 'accepted') {
        throw StateError('Only the buyer or seller can cancel this reservation');
      }
      if (listingId == null || buyerId == null) {
        throw StateError('Reservation information is incomplete');
      }

      final listingRef = _firestore.collection('listings').doc(listingId);
      final listingSnapshot = await transaction.get(listingRef);
      final listing = listingSnapshot.data();
      if (!listingSnapshot.exists ||
          listing?['status'] != 'reserved' ||
          listing?['reserved_offer_id'] != offerId ||
          listing?['reserved_for_user_id'] != buyerId) {
        throw StateError('This reservation is no longer active');
      }

      final transactionRef =
          _firestore.collection('transactions').doc(offerId);
      final transactionSnapshot = await transaction.get(transactionRef);
      final transactionData = transactionSnapshot.data();
      if (transactionSnapshot.exists &&
          transactionData?['status'] != 'reserved') {
        throw StateError('This transaction can no longer be cancelled');
      }

      transaction.update(offerRef, {
        'status': 'cancelled',
        'updated_at': FieldValue.serverTimestamp(),
        'last_action_by': userId,
      });
      transaction.update(listingRef, {
        'status': 'active',
        'reserved_for_user_id': FieldValue.delete(),
        'reserved_offer_id': FieldValue.delete(),
        'reserved_at': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (transactionSnapshot.exists) {
        transaction.update(transactionRef, {
          'status': 'cancelled',
          'cancelled_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'last_action_by': userId,
        });
      }

      if (chatId != null) {
        final updateMessageRef = _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc();
        transaction.set(updateMessageRef, {
          'senderId': userId,
          'offerId': offerId,
          'listingId': listingId,
          'offerStatus': 'cancelled',
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
          'read': false,
          'type': 'offer_update',
        });
        transaction.update(_firestore.collection('chats').doc(chatId), {
          'lastMessage': isBuyer ? 'Buyer withdrew from reservation' : 'Reservation released',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'deletedFor': FieldValue.arrayRemove([buyerId, sellerId]),
        });
      }

      cancelledOffer = {...offer, 'status': 'cancelled'};
    });

    final sellerId = cancelledOffer['seller_id']?.toString();
    final buyerId = cancelledOffer['buyer_id']?.toString();
    final cancelledByBuyer = userId == buyerId;
    final recipientId = cancelledByBuyer ? sellerId : buyerId;
    if (recipientId == null) return;

    try {
      await _notificationService.createNotification(
        recipientId: recipientId,
        type: 'offer',
        title: cancelledByBuyer ? 'Buyer withdrew' : 'Reservation released',
        body: cancelledByBuyer
            ? 'The buyer withdrew from ${cancelledOffer['listing_title'] ?? 'the item'}. It is available again.'
            : '${cancelledOffer['listing_title'] ?? 'The item'} is available again.',
        relatedListingId: cancelledOffer['listing_id']?.toString(),
        relatedUserId: userId,
        additionalData: {
          'offer_id': offerId,
          'offer_status': 'cancelled',
          'chat_id': cancelledOffer['chat_id'],
        },
      );
    } catch (_) {
      // Reservation release is already committed; notification is best-effort.
    }
  }

  int _offerTimestampMillis(Map<String, dynamic> offer) {
    final updatedAt = offer['updated_at'];
    if (updatedAt is Timestamp) return updatedAt.millisecondsSinceEpoch;

    final createdAt = offer['created_at'];
    if (createdAt is Timestamp) return createdAt.millisecondsSinceEpoch;

    return 0;
  }

  double _normalizeMoney(double amount) {
    return (amount * 100).roundToDouble() / 100;
  }

  String _formatAmount(double amount) => '₱${amount.toStringAsFixed(2)}';
}
