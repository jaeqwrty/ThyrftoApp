import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic> currentUser;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    required this.currentUser,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _database = DatabaseService();
  bool _opening = false;

  static const _ink = Color(0xFF17131F);
  static const _muted = Color(0xFF6B6475);
  static const _line = Color(0xFFE5DFEC);
  static const _surface = Color(0xFFFBFAFC);
  static const _accent = Color(0xFF5B2A6F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Transaction Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('transactions')
            .doc(widget.transactionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _messageState(
              Icons.lock_outline_rounded,
              'Unable to open this transaction.',
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _messageState(
              Icons.receipt_long_outlined,
              'This transaction is no longer available.',
            );
          }

          final data = snapshot.data!.data()!;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null ||
              (data['buyer_id'] != currentUserId &&
                  data['seller_id'] != currentUserId)) {
            return _messageState(
              Icons.lock_outline_rounded,
              'You do not have access to this transaction.',
            );
          }

          final status = data['status']?.toString() ?? 'reserved';
          final title = data['listing_title']?.toString() ?? 'Listing';
          final price = (data['agreed_price'] as num?)?.toDouble();
          final isBuyer = data['buyer_id'] == currentUserId;
          final completedAt = data['completed_at'] as Timestamp?;
          final buyerConfirmed = data['buyer_confirmed'] == true;
          final sellerConfirmed = data['seller_confirmed'] == true;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.09),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            status == 'completed'
                                ? Icons.verified_rounded
                                : Icons.handshake_outlined,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isBuyer ? 'You are the buyer' : 'You are the seller',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _detailRow(
                      'Agreed price',
                      price == null
                          ? 'Not available'
                          : '₱${NumberFormat('#,##0.00').format(price)}',
                    ),
                    _detailRow('Status', _statusLabel(status)),
                    if (completedAt != null)
                      _detailRow(
                        'Completed',
                        DateFormat('MMM d, yyyy · h:mm a')
                            .format(completedAt.toDate()),
                      ),
                    _detailRow('Transaction ID', widget.transactionId),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exchange confirmation',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _confirmationRow('Buyer', buyerConfirmed),
                    const SizedBox(height: 8),
                    _confirmationRow('Seller', sellerConfirmed),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _opening
                          ? null
                          : () => _openListing(data['listing_id']?.toString()),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('View Listing'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _opening ? null : () => _openChat(data),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: const Text('Open Chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmationRow(String role, bool confirmed) {
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: confirmed ? Colors.green : _muted,
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(
          '$role · ${confirmed ? 'Confirmed' : 'Waiting'}',
          style: TextStyle(
            color: confirmed ? _ink : _muted,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _messageState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: _muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'reserved':
        return 'Reserved / In progress';
      default:
        return status;
    }
  }

  Future<void> _openListing(String? listingId) async {
    if (listingId == null || listingId.isEmpty) return;
    setState(() => _opening = true);
    try {
      final listing = await _database.getListingById(listingId);
      if (!mounted) return;
      if (listing == null) {
        _showError('This listing is no longer available.');
        return;
      }
      await Navigator.push(
        context,
        AppPageRoute.fadeThrough(
          builder: (_) => ListingDetailPage(
            listing: listing,
            user: widget.currentUser,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> transaction) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final chatId = transaction['chat_id']?.toString();
    if (currentUserId == null || chatId == null || chatId.isEmpty) return;

    final otherUserId = transaction['buyer_id'] == currentUserId
        ? transaction['seller_id']?.toString()
        : transaction['buyer_id']?.toString();
    if (otherUserId == null || otherUserId.isEmpty) return;

    setState(() => _opening = true);
    try {
      final otherUser = await _database.getUserProfile(otherUserId);
      if (!mounted) return;
      if (otherUser == null) {
        _showError('Conversation participant is unavailable.');
        return;
      }

      await Navigator.push(
        context,
        AppPageRoute.fadeThrough(
          builder: (_) => ConversationPage(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUser['fullName'] ??
                otherUser['full_name'] ??
                otherUser['username'] ??
                'User',
            currentUser: widget.currentUser,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
