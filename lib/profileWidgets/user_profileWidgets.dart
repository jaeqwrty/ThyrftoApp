import 'package:flutter/material.dart';
import 'package:thryfto/services/location_service.dart';
import 'package:thryfto/services/rating_service.dart';
import 'package:thryfto/pages/listing_detail_page.dart';

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
    return FutureBuilder<Map<String, dynamic>?>(
      future: locationService.getUserLocation(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 20);
        }
        String locationDisplay = 'Location not set';
        IconData locationIcon = Icons.location_off;
        Color locationColor = Colors.grey[500]!;

        if (snapshot.hasData && snapshot.data != null) {
          final address = snapshot.data!['address'] as String?;
          if (address != null &&
              address.isNotEmpty &&
              !address.startsWith('Lat:')) {
            locationDisplay = address;
            locationIcon = Icons.location_on;
            locationColor = const Color(0xFF8B5CF6);
          }
        }
        return Row(
          children: [
            Icon(locationIcon, size: 16, color: locationColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                locationDisplay,
                style: TextStyle(
                  fontSize: 14,
                  color: locationColor,
                  fontWeight: locationIcon == Icons.location_on
                      ? FontWeight.w600
                      : FontWeight.normal,
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
                color: ratingsCount > 0 ? Colors.amber.shade200 : Colors.grey[300]!,
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
                  ratingsCount > 0 ? averageRating.toStringAsFixed(1) : 'No ratings',
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
              isFavorite ? Icons.notifications_active : Icons.notifications_none,
              size: 16,
            ),
            label: Text(
              isFavorite ? 'Notifications On' : 'Get Notified',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFavorite 
                  ? const Color(0xFF8B5CF6) 
                  : Colors.white,
              foregroundColor: isFavorite 
                  ? Colors.white 
                  : const Color(0xFF8B5CF6),
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
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
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

  const ListingCard({
    super.key,
    required this.listing,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrls = listing['image_urls'] as List<dynamic>? ?? [];
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrls.isNotEmpty
                    ? Image.network(
                        imageUrls[0],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${listing['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing['title'] ?? 'No title',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(
                        listing['size'] ?? 'N/A',
                        Colors.purple.shade50,
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 6),
                      _buildBadge(
                        listing['condition'] ?? 'N/A',
                        Colors.green.shade50,
                        Colors.green.shade700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
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