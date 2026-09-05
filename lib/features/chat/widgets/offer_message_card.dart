import 'package:flutter/material.dart';
import 'package:thryfto/core/services/offer_service.dart';
import 'package:thryfto/core/services/transaction_service.dart';

class OfferMessageCard extends StatefulWidget {
  final String offerId;
  final String currentUserId;

  const OfferMessageCard({
    super.key,
    required this.offerId,
    required this.currentUserId,
  });

  @override
  State<OfferMessageCard> createState() => _OfferMessageCardState();
}

class _OfferMessageCardState extends State<OfferMessageCard> {
  final OfferService _offerService = OfferService();
  final TransactionService _transactionService = TransactionService();
  bool _isProcessing = false;

  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _accent = Color(0xFFA8752A);
  static const Color _wine = Color(0xFF5B2A6F);

  @override
  Widget build(BuildContext context) {
    if (widget.offerId.isEmpty) {
      return const _OfferUnavailable();
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _offerService.getOfferStream(widget.offerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        final offer = snapshot.data;
        if (offer == null) return const _OfferUnavailable();

        final sellerId = offer['seller_id']?.toString();
        final buyerId = offer['buyer_id']?.toString();
        final status = offer['status']?.toString() ?? 'pending';
        final amount = (offer['amount'] as num?)?.toDouble() ?? 0;
        final initialAmount =
            (offer['initial_amount'] as num?)?.toDouble() ?? amount;
        final listingPrice =
            (offer['listing_price'] as num?)?.toDouble() ?? 0;
        final title = offer['listing_title']?.toString() ?? 'Listing';
        final isSeller = widget.currentUserId == sellerId;
        final isBuyer = widget.currentUserId == buyerId;
        final canSellerRespond = isSeller && status == 'pending';
        final canBuyerRespond = isBuyer && status == 'countered';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: _accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Listed at ${_money(listingPrice)}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                status == 'countered' ? 'Counter offer' : 'Offer amount',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _money(amount),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (status == 'countered' && amount != initialAmount) ...[
                const SizedBox(height: 2),
                Text(
                  'Original buyer offer: ${_money(initialAmount)}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildActionArea(
                offer: offer,
                status: status,
                amount: amount,
                isSeller: isSeller,
                isBuyer: isBuyer,
                canSellerRespond: canSellerRespond,
                canBuyerRespond: canBuyerRespond,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionArea({
    required Map<String, dynamic> offer,
    required String status,
    required double amount,
    required bool isSeller,
    required bool isBuyer,
    required bool canSellerRespond,
    required bool canBuyerRespond,
  }) {
    final listingId = offer['listing_id']?.toString();
    if (listingId == null || listingId.isEmpty) {
      return _buildStatusText(_statusHelp(status, isSeller: isSeller));
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _offerService.watchListingState(listingId),
      builder: (context, listingSnapshot) {
        if (listingSnapshot.connectionState == ConnectionState.waiting &&
            !listingSnapshot.hasData) {
          return _buildStatusText('Checking listing availability…');
        }

        final listing = listingSnapshot.data;
        final listingStatus = listing?['status']?.toString();
        final isMarketplaceActive = listingStatus == 'active';
        final isThisReservation = listingStatus == 'reserved' &&
            listing?['reserved_offer_id']?.toString() == offer['id']?.toString();

        if (status == 'accepted' && isThisReservation) {
          if (isSeller || isBuyer) {
            return _buildReservedTransactionActions(
              offer: offer,
              isSeller: isSeller,
              isBuyer: isBuyer,
            );
          }
          return _buildStatusText('This item is reserved.');
        }

        if (status == 'accepted' && listingStatus == 'sold') {
          final completedThroughThisOffer =
              listing?['sold_transaction_id']?.toString() ==
                  offer['id']?.toString();
          return _buildStatusText(completedThroughThisOffer
              ? 'Transaction completed. Both sides confirmed the exchange and the listing is sold. You can now leave a verified review from this user’s profile.'
              : 'Offer accepted. This listing is now marked sold.');
        }

        if (canSellerRespond) {
          if (isMarketplaceActive) return _sellerActions(offer, amount);
          return _blockedOfferActions(
            offerId: offer['id'].toString(),
            message: listingStatus == 'reserved'
                ? 'This item is reserved for another buyer. Close this pending offer if it will not proceed.'
                : 'This listing is no longer available for negotiation.',
          );
        }

        if (canBuyerRespond) {
          if (isMarketplaceActive) return _buyerCounterActions(offer);
          return _blockedOfferActions(
            offerId: offer['id'].toString(),
            message: listingStatus == 'reserved'
                ? 'This item has been reserved. You can decline this counter offer.'
                : 'This listing is no longer available for negotiation.',
          );
        }

        if ((status == 'pending' || status == 'countered') &&
            listingStatus != 'active') {
          return _buildStatusText(
            listingStatus == 'reserved'
                ? 'This listing is reserved for another accepted offer.'
                : 'This listing is no longer available for negotiation.',
          );
        }

        return _buildStatusText(_statusHelp(status, isSeller: isSeller));
      },
    );
  }

  Widget _buildReservedTransactionActions({
    required Map<String, dynamic> offer,
    required bool isSeller,
    required bool isBuyer,
  }) {
    final offerId = offer['id']?.toString() ?? '';
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _transactionService.watchTransactionForOffer(offerId),
      builder: (context, snapshot) {
        final transaction = snapshot.data;
        final transactionStatus = transaction?['status']?.toString() ?? 'reserved';
        final buyerConfirmed = transaction?['buyer_confirmed'] == true;
        final sellerConfirmed = transaction?['seller_confirmed'] == true;
        final currentUserConfirmed = isBuyer
            ? buyerConfirmed
            : isSeller
                ? sellerConfirmed
                : false;

        if (transactionStatus == 'completed') {
          return _buildStatusText(
            'Transaction completed. Both sides confirmed the exchange and the listing is sold. You can now leave a verified review from this user’s profile.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusText(
              'Confirm only after the item and agreed payment have been exchanged. The listing becomes sold after both sides confirm.',
            ),
            const SizedBox(height: 10),
            _transactionConfirmationRow(
              label: 'Buyer confirmation',
              confirmed: buyerConfirmed,
            ),
            const SizedBox(height: 6),
            _transactionConfirmationRow(
              label: 'Seller confirmation',
              confirmed: sellerConfirmed,
            ),
            const SizedBox(height: 10),
            if (!currentUserConfirmed)
              ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _confirmTransactionCompletion(offerId),
                icon: const Icon(Icons.handshake_outlined, size: 17),
                label: const Text('Confirm Exchange Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              _buildStatusText(
                buyerConfirmed && sellerConfirmed
                    ? 'Both sides confirmed the exchange.'
                    : 'You confirmed the exchange. Waiting for the other participant.',
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _confirmReleaseReservation(
                        offerId,
                        asBuyer: isBuyer,
                      ),
              icon: Icon(
                isBuyer ? Icons.close_rounded : Icons.lock_open_outlined,
                size: 17,
              ),
              label: Text(
                isBuyer
                    ? 'Withdraw from Reservation'
                    : 'Release Reservation',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isBuyer ? Colors.redAccent : _accent,
                side: BorderSide(
                  color: isBuyer ? Colors.redAccent : _accent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _transactionConfirmationRow({
    required String label,
    required bool confirmed,
  }) {
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 17,
          color: confirmed ? Colors.green : _muted,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$label · ${confirmed ? 'Confirmed' : 'Waiting'}',
            style: TextStyle(
              color: confirmed ? _ink : _muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _blockedOfferActions({
    required String offerId,
    required String message,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusText(message),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _isProcessing ? null : () => _respond(offerId, 'declined'),
          child: const Text(
            'Decline offer',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _sellerActions(Map<String, dynamic> offer, double currentAmount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _respond(offer['id'].toString(), 'accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing
                    ? null
                    : () => _showCounterDialog(
                          offer['id'].toString(),
                          currentAmount,
                        ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _wine,
                  side: const BorderSide(color: _wine),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Counter'),
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isProcessing
                ? null
                : () => _respond(offer['id'].toString(), 'declined'),
            child: const Text(
              'Decline offer',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buyerCounterActions(Map<String, dynamic> offer) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing
                ? null
                : () => _respond(offer['id'].toString(), 'accepted'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Accept Counter'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing
                ? null
                : () => _respond(offer['id'].toString(), 'declined'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Decline'),
          ),
        ),
      ],
    );
  }

  Future<void> _showCounterDialog(String offerId, double currentAmount) async {
    final controller = TextEditingController();
    String? errorText;

    final counterAmount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Counter Offer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buyer offered ${_money(currentAmount)}. Enter your counter amount.',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Counter amount',
                  prefixText: '₱ ',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(
                  controller.text.trim().replaceAll(',', ''),
                );
                if (amount == null || amount <= 0 || amount == currentAmount) {
                  setModalState(() {
                    errorText = amount == currentAmount
                        ? 'Enter a different amount'
                        : 'Enter a valid amount';
                  });
                  return;
                }
                Navigator.pop(dialogContext, amount);
              },
              child: const Text('Send Counter'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (counterAmount != null && mounted) {
      await _respond(offerId, 'countered', counterAmount: counterAmount);
    }
  }

  Future<void> _respond(
    String offerId,
    String action, {
    double? counterAmount,
  }) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _offerService.respondToOffer(
        offerId: offerId,
        action: action,
        counterAmount: counterAmount,
      );
      if (!mounted) return;
      final message = action == 'countered'
          ? 'Counter offer sent'
          : action == 'accepted'
              ? 'Offer accepted'
              : 'Offer declined';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _releaseReservation(String offerId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _offerService.releaseReservationForOffer(offerId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation released'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmTransactionCompletion(String offerId) async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Exchange Complete?'),
        content: const Text(
          'Confirm only after the item and the agreed payment have been exchanged. The listing will be marked sold once both buyer and seller confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final result =
          await _transactionService.confirmCompletionForOffer(offerId);
      if (!mounted) return;

      final completed = result['completed'] == true;
      final alreadyConfirmed = result['already_confirmed'] == true;
      final message = completed
          ? 'Transaction completed. Listing marked as sold.'
          : alreadyConfirmed
              ? 'Your confirmation is already recorded.'
              : 'Confirmation recorded. Waiting for the other participant.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmReleaseReservation(
    String offerId, {
    required bool asBuyer,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(asBuyer ? 'Withdraw from Reservation?' : 'Release Reservation?'),
        content: Text(
          asBuyer
              ? 'The item will become available to other shoppers again.'
              : 'The accepted offer will be cancelled and the item will become available again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Reservation'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(asBuyer ? 'Withdraw' : 'Release'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _releaseReservation(offerId);
    }
  }

  Widget _statusBadge(String status) {
    final label = switch (status) {
      'accepted' => 'Accepted',
      'declined' => 'Declined',
      'cancelled' => 'Cancelled',
      'countered' => 'Countered',
      _ => 'Pending',
    };
    final color = switch (status) {
      'accepted' => Colors.green,
      'declined' => Colors.redAccent,
      'cancelled' => Colors.grey,
      'countered' => _wine,
      _ => _accent,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  static String _money(double amount) => '₱${amount.toStringAsFixed(2)}';

  String _statusHelp(String status, {required bool isSeller}) {
    return switch (status) {
      'accepted' => isSeller
          ? 'Offer accepted. The item is reserved for this buyer.'
          : 'Offer accepted. This item is now reserved for you.',
      'declined' => 'This offer was declined.',
      'cancelled' => 'The reservation was released and this offer is no longer active.',
      'countered' => isSeller
          ? 'Counter sent. Waiting for the buyer to respond.'
          : 'The seller sent a counter offer.',
      _ => isSeller
          ? 'Review the buyer’s offer below.'
          : 'Offer sent. Waiting for the seller to respond.',
    };
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Bad state: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}

class _OfferUnavailable extends StatelessWidget {
  const _OfferUnavailable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5DFEC)),
      ),
      child: const Text(
        'Offer details are no longer available.',
        style: TextStyle(color: Color(0xFF6B6475), fontSize: 12),
      ),
    );
  }
}
