import 'package:flutter/material.dart';
import 'package:thryfto/commonWidgets/image_placeholder.dart';
import 'package:thryfto/commonWidgets/tag.dart';
import 'package:thryfto/commonWidgets/user_avatar.dart';
import 'package:thryfto/services/database_service.dart';

/// Reusable action button for listings (like, comment, share, bookmark)
class ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  final int? count;
  final bool showCount;

  const ActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
    this.count,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0, // Increased horizontal padding for better spacing
          vertical: 6.0,   // Increased vertical padding
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Colors.black,
              size: 24,
            ),
            if (showCount && count != null && count! > 0) ...[
              const SizedBox(width: 8), // Increased space between icon and text
              Text(
                _formatCount(count!),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}

/// Like button with stream builder
class LikeButton extends StatelessWidget {
  final String listingId;
  final int initialLikeCount;
  final DatabaseService db;

  const LikeButton({
    super.key,
    required this.listingId,
    required this.initialLikeCount,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: db.isListingLikedStream(listingId),
      initialData: false,
      builder: (context, likeSnapshot) {
        final isLiked = likeSnapshot.data ?? false;

        return StreamBuilder<Map<String, dynamic>?>(
          stream: db.getListingStream(listingId),
          initialData: null,
          builder: (context, listingSnapshot) {
            final likeCount = listingSnapshot.data?['likes'] ?? initialLikeCount;

            return ActionButton(
              icon: isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? Colors.red : Colors.black,
              count: likeCount,
              onTap: () async {
                await db.toggleLikeWithNotification(listingId);
              },
            );
          },
        );
      },
    );
  }
}

/// Comment button with stream builder
class CommentButton extends StatelessWidget {
  final String listingId;
  final DatabaseService db;
  final VoidCallback onTap;

  const CommentButton({
    super.key,
    required this.listingId,
    required this.db,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: db.getCommentCountStream(listingId),
      builder: (context, snapshot) {
        final commentCount = snapshot.data ?? 0;
        return ActionButton(
          icon: Icons.mode_comment_outlined,
          count: commentCount,
          onTap: onTap,
        );
      },
    );
  }
}

/// Bookmark button with stream builder
class BookmarkButton extends StatelessWidget {
  final String listingId;
  final DatabaseService db;

  const BookmarkButton({
    super.key,
    required this.listingId,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: db.isListingBookmarkedStream(listingId),
      initialData: false,
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;
        return ActionButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          color: isBookmarked ? const Color(0xFF8B5CF6) : Colors.black,
          showCount: false,
          onTap: () async {
            try {
              await db.toggleBookmark(listingId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isBookmarked
                          ? 'Removed from bookmarks'
                          : 'Added to bookmarks',
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
        );
      },
    );
  }
}

/// User info header for listings
class ListingUserHeader extends StatelessWidget {
  final String username;
  final String location;
  final VoidCallback? onTap;

  const ListingUserHeader({
    super.key,
    required this.username,
    required this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Increased vertical padding from 12 to 16
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                UserAvatar(username: username, radius: 18),
                const SizedBox(width: 12), // Increased from 10
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4), // Increased from 2
                    Text(
                      location,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Listing image display
class ListingImage extends StatelessWidget {
  final List<dynamic>? imageUrls;
  final double height;

  const ListingImage({
    super.key,
    required this.imageUrls,
    this.height = 350, // Decreased by 10 (from 400 to 390)
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrls != null && imageUrls!.isNotEmpty;

    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[200],
      child: hasImage
          ? Image.network(
              imageUrls![0],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const ImagePlaceholder(size: 50),
            )
          : const ImagePlaceholder(size: 50),
    );
  }
}

/// Listing details section (price, title, size, condition, description)
class ListingDetails extends StatelessWidget {
  final Map<String, dynamic> listing;

  const ListingDetails({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price and title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Text(
                '₱ ${listing['price']?.toStringAsFixed(2) ?? '0.00'} • ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              Expanded(
                child: Text(
                  listing['title'] ?? 'No title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10), // Increased from 4
        // Size and condition
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              TagBadge.size(listing['size'] ?? 'N/A'),
              const SizedBox(width: 8),
              TagBadge.condition(listing['condition'] ?? 'N/A'),
            ],
          ),
        ),
        const SizedBox(height: 12), // Increased from 8
        // Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            listing['description'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4, // Added line height for readability
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 20), // Added spacing at the bottom
      ],
    );
  }
}