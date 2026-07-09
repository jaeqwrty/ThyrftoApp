import 'package:flutter/material.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/services/rating_service.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';

/// Widget for displaying user location
class LocationWidget extends StatelessWidget {
  final String userId;
  final LocationService locationService;

  const LocationWidget({
    super.key,
    required this.userId,
    required this.locationService,
  });

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17131F);
    const muted = Color(0xFF6B6475);

    return FutureBuilder<Map<String, dynamic>?>(
      future: locationService.getUserLocation(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        String locationDisplay = 'Location not set';
        IconData locationIcon = Icons.location_off;
        Color locationColor = muted;

        if (snapshot.hasData && snapshot.data != null) {
          final address = snapshot.data!['address'] as String?;
          if (address != null &&
              address.isNotEmpty &&
              !address.startsWith('Lat:')) {
            locationDisplay = address;
            locationIcon = Icons.location_on;
            locationColor = ink;
          }
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(locationIcon, size: 14, color: locationColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                locationDisplay,
                style: TextStyle(
                  fontSize: 11,
                  color: locationColor,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Compact rating indicator widget
class RatingIndicator extends StatelessWidget {
  final String userId;
  final RatingService ratingService;
  final VoidCallback onTap;

  const RatingIndicator({
    super.key,
    required this.userId,
    required this.ratingService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ratingService.getSellerRatingStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final averageRating = stats['average_rating'] as double;
        final ratingsCount = stats['ratings_count'] as int;

        return GestureDetector(
          onTap: ratingsCount > 0 ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: ratingsCount > 0 ? Colors.amber.shade50 : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ratingsCount > 0
                    ? Colors.amber.shade200
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: ratingsCount > 0 ? Colors.amber : Colors.grey[400],
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  ratingsCount > 0
                      ? averageRating.toStringAsFixed(1)
                      : 'No ratings',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ratingsCount > 0 ? Colors.black87 : Colors.grey[500],
                  ),
                ),
                if (ratingsCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($ratingsCount)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey[600]),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact action buttons for profile
class ProfileActionButtons extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onMessage;
  final VoidCallback onRate;

  const ProfileActionButtons({
    super.key,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onMessage,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary Action Button - More compact
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton.icon(
            onPressed: onToggleFavorite,
            icon: Icon(
              isFavorite
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              size: 16,
            ),
            label: Text(
              isFavorite ? 'Notifications On' : 'Get Notified',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isFavorite ? const Color(0xFF8B5CF6) : Colors.white,
              foregroundColor:
                  isFavorite ? Colors.white : const Color(0xFF8B5CF6),
              side: BorderSide(
                color: const Color(0xFF8B5CF6),
                width: isFavorite ? 0 : 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
              elevation: isFavorite ? 2 : 0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Secondary Action Buttons - More compact
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.message_outlined, size: 14),
                  label: const Text('Message',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.star_outline, size: 14),
                  label: const Text('Rate',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Listing card widget
class ListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> currentUser;
  final bool showBookmarkBadge;

  const ListingCard({
    super.key,
    required this.listing,
    required this.currentUser,
    this.showBookmarkBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrls = listing['image_urls'] as List<dynamic>? ?? [];
    final bool isSold = listing['status'] == 'sold';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListingDetailPage(
            listing: listing,
            user: currentUser,
          ),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5DFEC)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF17131F).withValues(alpha: 0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrls.isNotEmpty
                      ? Image.network(
                          imageUrls[0],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => _buildImagePlaceholder(),
                        )
                      : _buildImagePlaceholder(),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isSold)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'SOLD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  if (isSold)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  if (showBookmarkBadge)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5DFEC),
                          ),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: Color(0xFF17131F),
                          size: 17,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatPrice(listing['price']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isSold
                            ? const Color(0xFF8E8797)
                            : const Color(0xFF17131F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      listing['title'] ?? 'No title',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        decoration: isSold ? TextDecoration.lineThrough : null,
                        color: isSold
                            ? const Color(0xFF8E8797)
                            : const Color(0xFF2B2633),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _buildBadge(listing['size'] ?? 'N/A'),
                        const SizedBox(width: 6),
                        Flexible(
                          child: _buildBadge(listing['condition'] ?? 'N/A'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price is num) return 'PHP ${price.toStringAsFixed(2)}';
    final parsed = double.tryParse(price?.toString() ?? '');
    return 'PHP ${(parsed ?? 0).toStringAsFixed(2)}';
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5DFEC)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF6B6475),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF4F1F7),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: Color(0xFFAAA3B5),
        ),
      ),
    );
  }
}

/// Helper function to format dates
String formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inDays > 7) {
    return '${date.day}/${date.month}/${date.year}';
  } else if (diff.inDays > 0) {
    return '${diff.inDays}d ago';
  } else if (diff.inHours > 0) {
    return '${diff.inHours}h ago';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes}m ago';
  } else {
    return 'Just now';
  }
}
