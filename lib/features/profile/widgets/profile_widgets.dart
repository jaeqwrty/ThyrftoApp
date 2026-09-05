import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/shared/widgets/image_placeholder.dart';
import 'package:thryfto/shared/widgets/tag.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/features/profile/widgets/user_profileWidgets.dart';

/// Profile header with avatar, name, username, and location
/// Profile header with avatar, name, username, and location
class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Use Firebase Auth user ID to match Firestore document
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final fullName = user['fullName'] ?? user['full_name'] ?? 'User';
    final username = user['username'] ?? 'unknown';
    final profileImageUrl =
        user['profileImageUrl'] as String?; // Get profile image URL

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar and name
          Row(
            children: [
              // Profile Avatar - Now shows image if available
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                backgroundImage:
                    (profileImageUrl != null && profileImageUrl.isNotEmpty)
                        ? NetworkImage(profileImageUrl)
                        : null,
                child: (profileImageUrl == null || profileImageUrl.isEmpty)
                    ? Text(
                        fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null, // Don't show text if image is present
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@$username',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // LOCATION DISPLAY - Fetches from Firestore
                    FutureBuilder<Map<String, dynamic>?>(
                      future: LocationService().getUserLocation(userId),
                      builder: (context, snapshot) {
                        // Debug output
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Loading location...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          );
                        }

                        // Check if location data exists
                        final locationData = snapshot.data;
                        final hasLocation = locationData != null &&
                            locationData['latitude'] != null &&
                            locationData['longitude'] != null;

                        String displayText;
                        Color textColor;
                        IconData iconData;

                        if (hasLocation) {
                          // Show address or coordinates
                          final address = locationData['address'] as String?;
                          if (address != null && !address.startsWith('Lat:')) {
                            displayText = address;
                          } else {
                            final lat = locationData['latitude'];
                            final lon = locationData['longitude'];
                            displayText =
                                'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
                          }
                          textColor = AppColors.primary;
                          iconData = Icons.location_on;
                        } else {
                          displayText = 'Location not set';
                          textColor = Colors.grey[500]!;
                          iconData = Icons.location_off;
                        }

                        return Row(
                          children: [
                            Icon(
                              iconData,
                              size: 16,
                              color: textColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                displayText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                  fontWeight: hasLocation
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
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Edit Profile Button
        ],
      ),
    );
  }
}

/// Listing card for grid view (used in both My Listings and Bookmarks)
class ListingGridCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;
  final bool showBookmarkBadge;

  const ListingGridCard({
    super.key,
    required this.listing,
    required this.user,
    this.showBookmarkBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrls = listing['image_urls'] as List<dynamic>? ?? [];
    final hasImage = imageUrls.isNotEmpty;
    final bool isSold = listing['status'] == 'sold';
    final bool isReserved = listing['status'] == 'reserved';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          AppPageRoute.fadeThrough(
            builder: (context) => ListingDetailPage(
              listing: listing,
              user: user,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: hasImage
                            ? Image.network(
                                imageUrls[0],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const ImagePlaceholder(),
                              )
                            : const ImagePlaceholder(),
                      ),

                      if (isSold || isReserved)
                        Positioned(
                          top: 8,
                          left:
                              8, // Placed on left to avoid conflict with bookmark on right
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isReserved
                                  ? const Color(0xFFA8752A)
                                  : Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isReserved ? 'RESERVED' : 'SOLD',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                      // Optional: Dark overlay for sold items
                      if (isSold)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Details Section
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₱${listing['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          // Grey out the price if sold
                          color: isSold ? Colors.grey : AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing['title'] ?? 'No title',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          // Strike-through and grey color if sold
                          decoration:
                              isSold ? TextDecoration.lineThrough : null,
                          color: isSold ? Colors.grey : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TagBadge.size(listing['size'] ?? 'N/A'),
                          const SizedBox(width: 6),
                          Flexible(
                            child: TagBadge.condition(
                                listing['condition'] ?? 'N/A'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Existing bookmark badge
            if (showBookmarkBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            // Optional bookmark badge
            if (showBookmarkBadge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bookmark,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Reusable grid view for listings
class ListingsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> listings;
  final Map<String, dynamic> user;
  final bool showBookmarkBadge;

  const ListingsGrid({
    super.key,
    required this.listings,
    required this.user,
    this.showBookmarkBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) => ListingCard(
        listing: listings[index],
        currentUser: user,
        showBookmarkBadge: showBookmarkBadge,
      ),
    );
  }
}

/// Settings menu item
class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.accent),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: onTap,
    );
  }
}

/// Confirmation dialog
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: confirmColor ?? Colors.red,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
      ),
    );
  }
}
