import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:thryfto/core/navigation/deep_link_service.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/features/transactions/pages/transaction_detail_page.dart';

class DeepLinkRouter {
  const DeepLinkRouter._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DatabaseService _database = DatabaseService();

  static Future<bool> open(
    BuildContext context,
    Uri uri, {
    required Map<String, dynamic> currentUser,
  }) async {
    final target = DeepLinkTarget.parse(uri);
    if (target == null) return false;

    try {
      switch (target.kind) {
        case DeepLinkKind.listing:
          final listing = await _database.getListingById(target.id);
          if (listing == null) {
            _showError(context, 'This listing is no longer available.');
            return true;
          }
          if (!context.mounted) return true;
          Navigator.of(context).push(
            AppPageRoute.fadeThrough(
              builder: (_) => ListingDetailPage(
                listing: listing,
                user: currentUser,
              ),
            ),
          );
          return true;

        case DeepLinkKind.chat:
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) return false;

          final chatDoc =
              await _firestore.collection('chats').doc(target.id).get();
          if (!chatDoc.exists) {
            _showError(context, 'This conversation is no longer available.');
            return true;
          }

          final participants =
              List<String>.from(chatDoc.data()?['participants'] ?? const []);
          if (!participants.contains(currentUserId)) {
            _showError(context, 'You do not have access to this conversation.');
            return true;
          }

          final otherUserId = participants.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
          if (otherUserId.isEmpty) {
            _showError(context, 'Conversation participant is unavailable.');
            return true;
          }

          final otherUser = await _database.getUserProfile(otherUserId);
          if (otherUser == null) {
            _showError(context, 'Conversation participant is unavailable.');
            return true;
          }
          if (!context.mounted) return true;

          Navigator.of(context).push(
            AppPageRoute.fadeThrough(
              builder: (_) => ConversationPage(
                chatId: target.id,
                otherUserId: otherUserId,
                otherUserName: otherUser['fullName'] ??
                    otherUser['full_name'] ??
                    otherUser['username'] ??
                    'User',
                currentUser: currentUser,
              ),
            ),
          );
          return true;

        case DeepLinkKind.transaction:
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) return false;

          final transactionDoc = await _firestore
              .collection('transactions')
              .doc(target.id)
              .get();
          if (!transactionDoc.exists) {
            _showError(context, 'This transaction is no longer available.');
            return true;
          }

          final data = transactionDoc.data()!;
          if (data['buyer_id'] != currentUserId &&
              data['seller_id'] != currentUserId) {
            _showError(context, 'You do not have access to this transaction.');
            return true;
          }
          if (!context.mounted) return true;

          Navigator.of(context).push(
            AppPageRoute.fadeThrough(
              builder: (_) => TransactionDetailPage(
                transactionId: target.id,
                currentUser: currentUser,
              ),
            ),
          );
          return true;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showError(context, 'You do not have access to this link.');
      } else {
        _showError(context, 'Unable to open this link right now.');
      }
      return true;
    } catch (_) {
      _showError(context, 'Unable to open this link right now.');
      return true;
    }
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
