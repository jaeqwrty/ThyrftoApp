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

  Future<String> createOffer({
    required Map<String, dynamic> listing,
    required String chatId,
    required double amount,
  }) async {
    final buyerId = currentUserId;
    final listingId = listing['id']?.toString();
    final sellerId = listing['seller_id']?.toString();
    final title = listing['title']?.toString() ?? 'Listing';
    final listingPrice = (listing['price'] as num?)?.toDouble() ??
        double.tryParse(listing['price']?.toString() ?? '') ??
        0;

    if (buyerId == null || listingId == null || sellerId == null) {
      throw StateError('Missing offer participants or listing');
    }
    if (buyerId == sellerId) {
      throw StateError('You cannot make an offer on your own listing');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Offer amount must be greater than zero');
    }

    final listingDoc =
        await _firestore.collection('listings').doc(listingId).get();
    if (!listingDoc.exists ||
        listingDoc.data()?['seller_id'] != sellerId ||
        listingDoc.data()?['status'] != 'active') {
      throw StateError('This listing is no longer available for offers');
    }

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
          (status == 'pending' || status == 'countered');
    });
    if (hasActiveOffer) {
      throw StateError('You already have an active offer for this listing');
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
      'initial_amount': amount,
      'amount': amount,
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
      'lastMessage': 'Offer: ${_formatAmount(amount)}',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'deletedFor': FieldValue.arrayRemove([buyerId, sellerId]),
    });

    await batch.commit();

    try {
      await _notificationService.createNotification(
        recipientId: sellerId,
        type: 'offer',
        title: 'New offer on $title',
        body: '${_formatAmount(amount)} offer received',
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

      if (action != 'declined') {
        final listingId = data['listing_id']?.toString();
        if (listingId == null) {
          throw StateError('The listing for this offer is unavailable');
        }
        final listing = await transaction.get(
          _firestore.collection('listings').doc(listingId),
        );
        if (!listing.exists || listing.data()?['status'] != 'active') {
          throw StateError('This listing is no longer available for offers');
        }
      }

      final nextAmount = action == 'countered' ? counterAmount! : currentAmount;
      transaction.update(offerRef, {
        'amount': nextAmount,
        'status': action,
        'updated_at': FieldValue.serverTimestamp(),
        'last_action_by': userId,
      });

      final chatId = data['chat_id']?.toString();
      if (chatId != null) {
        final label = action == 'countered'
            ? 'Counter offer: ${_formatAmount(nextAmount)}'
            : action == 'accepted'
                ? 'Offer accepted'
                : 'Offer declined';
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
            ? 'Offer accepted'
            : 'Offer declined';
    final notificationBody = status == 'countered'
        ? '${_formatAmount(amount)} counter offer on $title'
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

  String _formatAmount(double amount) => '₱${amount.toStringAsFixed(2)}';
}
