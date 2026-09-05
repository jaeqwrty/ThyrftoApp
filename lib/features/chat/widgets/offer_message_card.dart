import 'package:flutter/material.dart';
import 'package:thryfto/core/services/offer_service.dart';

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
              if (canSellerRespond) _sellerActions(offer, amount),
              if (canBuyerRespond) _buyerCounterActions(offer),
              if (!canSellerRespond && !canBuyerRespond)
                Text(
                  _statusHelp(status, isSeller: isSeller),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
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

  Widget _statusBadge(String status) {
    final label = switch (status) {
      'accepted' => 'Accepted',
      'declined' => 'Declined',
      'countered' => 'Countered',
      _ => 'Pending',
    };
    final color = switch (status) {
      'accepted' => Colors.green,
      'declined' => Colors.redAccent,
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
      'accepted' => 'Offer accepted. You can continue arranging the exchange in chat.',
      'declined' => 'This offer was declined.',
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
