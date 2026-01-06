import 'package:flutter/material.dart';
import 'package:thryfto/shared/widgets/image_placeholder.dart';
import 'package:thryfto/shared/widgets/tag.dart';
import 'package:thryfto/shared/widgets/user_avatar.dart';
import 'package:thryfto/shared/widgets/comments_modal.dart';
import 'package:thryfto/core/services/comments_service.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/features/profile/pages/user_profile_page.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/shared/widgets/share_modal.dart';

/// Format count helper function
String formatCount(int count) {
  if (count >= 1000000) {
    return '${(count / 1000000).toStringAsFixed(1)}M';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)}K';
  } else {
    return count.toString();
  }
}

/// Main Post Card Widget - Optimized to prevent unnecessary rebuilds
class PostCard extends StatefulWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;
  final DatabaseService db;
  final VoidCallback onBlockedUser;

  PostCard({
    super.key,
    required this.listing,
    required this.user,
    required this.db,
    required this.onBlockedUser,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: widget.db.getUserProfileStream(widget.listing['seller_id']),
      builder: (context, userSnapshot) {
        final seller = userSnapshot.data;
        final username = seller?['username'] ??
            seller?['fullName'] ??
            seller?['full_name'] ??
            'Unknown';
        final profileImageUrl = seller?['profileImageUrl'] as String?;
        final distanceText = widget.listing['distance_text'] as String?;
        final imageUrls = widget.listing['image_urls'] as List?;
        final imageCount = imageUrls?.length ?? 0;

        return FutureBuilder<Map<String, dynamic>?>(
          future:
              LocationService().getUserLocation(widget.listing['seller_id']),
          builder: (context, locationSnapshot) {
            String locationDisplay = 'Location not set';

            if (locationSnapshot.hasData && locationSnapshot.data != null) {
              final locationData = locationSnapshot.data!;
              final address = locationData['address'] as String?;

              if (address != null &&
                  address.isNotEmpty &&
                  !address.startsWith('Lat:') &&
                  address != 'Location set' &&
                  address != 'Location detected') {
                locationDisplay = address;
              }
            }

            return Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info header
                  PostUserHeader(
                    username: username,
                    profileImageUrl: profileImageUrl,
                    distanceText: distanceText,
                    locationDisplay: locationDisplay,
                    onTap: () async {
                      final sellerId = widget.listing['seller_id'];
                      if (sellerId != null &&
                          sellerId != widget.db.currentUserId) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfilePage(
                              userId: sellerId,
                              currentUser: widget.user,
                            ),
                          ),
                        );

                        if (result == 'blocked' && mounted) {
                          widget.onBlockedUser();
                        }
                      }
                    },
                  ),

                  // Item image
                  PostImage(
                    listing: widget.listing,
                    imageUrls: imageUrls,
                    imageCount: imageCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListingDetailPage(
                            listing: widget.listing,
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                  ),

                  // Action buttons
                  PostActions(
                    listingId: widget.listing['id'],
                    listing: widget.listing,
                    user: widget.user,
                    db: widget.db,
                  ),

                  // Price and title
                  PostPriceTitle(
                    listing: widget.listing,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListingDetailPage(
                            listing: widget.listing,
                            user: widget.user,
                          ),
                        ),
                      );
                    },
                  ),

                  // Size and condition
                  PostTags(listing: widget.listing),

                  // Description
                  PostDescription(
                    listing: widget.listing,
                    user: widget.user,
                  ),

                  const SizedBox(height: 12),

                  // Divider
                  Container(
                    height: 6,
                    color: AppColors.background,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// User Header Widget
class PostUserHeader extends StatelessWidget {
  final String username;
  final String? profileImageUrl;
  final String? distanceText;
  final String locationDisplay;
  final VoidCallback? onTap;

  const PostUserHeader({
    super.key,
    required this.username,
    this.profileImageUrl,
    this.distanceText,
    required this.locationDisplay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                          ? NetworkImage(profileImageUrl!)
                          : null,
                  child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    if (distanceText != null &&
                        distanceText != 'Location unavailable')
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 11,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distanceText!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            locationDisplay,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Post Image Widget
class PostImage extends StatelessWidget {
  final Map<String, dynamic> listing;
  final List? imageUrls;
  final int imageCount;
  final VoidCallback onTap;

  const PostImage({
    super.key,
    required this.listing,
    required this.imageUrls,
    required this.imageCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 400,
            width: double.infinity,
            color: Colors.grey[200],
            child: imageUrls != null && imageUrls!.isNotEmpty
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
          ),
          if (listing['status'] == 'sold')
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SOLD',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ),
          if (imageCount > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$imageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Post Actions Widget (Like, Comment, Share, Bookmark)
class PostActions extends StatelessWidget {
  final String listingId;
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;
  final DatabaseService db;

  const PostActions({
    super.key,
    required this.listingId,
    required this.listing,
    required this.user,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          LikeButtonOptimized(
            listingId: listingId,
            initialLikes: listing['likes'] ?? 0,
            db: db,
          ),
          const SizedBox(width: 4),

          // Updated: Uses Optimized Comment Button
          CommentButtonOptimized(
            listingId: listingId,
            user: user,
          ),

          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => ShareModal(listing: listing),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.share, size: 26),
            ),
          ),
          const Spacer(),
          BookmarkButtonOptimized(
            listingId: listingId,
            db: db,
          ),
        ],
      ),
    );
  }
}

/// Optimized Like Button - Prevents parent rebuild
class LikeButtonOptimized extends StatefulWidget {
  final String listingId;
  final int initialLikes;
  final DatabaseService db;

  const LikeButtonOptimized({
    super.key,
    required this.listingId,
    required this.initialLikes,
    required this.db,
  });

  @override
  State<LikeButtonOptimized> createState() => _LikeButtonOptimizedState();
}

class _LikeButtonOptimizedState extends State<LikeButtonOptimized>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Local state for optimistic updates
  bool? _optimisticLiked;
  int? _optimisticCount;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<bool>(
      stream: widget.db.isListingLikedStream(widget.listingId),
      builder: (context, likeSnapshot) {
        final isLiked = _optimisticLiked ?? likeSnapshot.data ?? false;

        return StreamBuilder<Map<String, dynamic>?>(
          stream: widget.db.getListingStream(widget.listingId),
          builder: (context, listingSnapshot) {
            // Reset optimistic state once stream updates
            if (listingSnapshot.hasData && _optimisticCount != null) {
              _optimisticCount = null;
            }
            if (likeSnapshot.hasData && _optimisticLiked != null) {
              _optimisticLiked = null;
            }

            final likeCount = _optimisticCount ??
                listingSnapshot.data?['likes'] ??
                widget.initialLikes;

            return InkWell(
              onTap: () {
                // Optimistic update - instant UI feedback
                setState(() {
                  _optimisticLiked = !isLiked;
                  _optimisticCount = isLiked ? likeCount - 1 : likeCount + 1;
                });

                // Actual database update
                widget.db.toggleLikeWithNotification(widget.listingId);
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.black,
                      size: 26,
                    ),
                    if (likeCount > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        formatCount(likeCount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Optimized Comment Button - Prevents parent rebuild
class CommentButtonOptimized extends StatefulWidget {
  final String listingId;
  final Map<String, dynamic> user;

  const CommentButtonOptimized({
    super.key,
    required this.listingId,
    required this.user,
  });

  @override
  State<CommentButtonOptimized> createState() => _CommentButtonOptimizedState();
}

class _CommentButtonOptimizedState extends State<CommentButtonOptimized>
    with AutomaticKeepAliveClientMixin {
  // Instantiate the service locally
  final CommentService _commentService = CommentService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<int>(
      // FIXED: Now calling getCommentCountStream from CommentService
      stream: _commentService.getCommentCountStream(widget.listingId),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData;
        final commentCount = snapshot.data ?? 0;

        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => CommentsModal(
                listingId: widget.listingId,
                user: widget.user,
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mode_comment_outlined,
                  size: 26,
                ),
                if (hasData && commentCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    formatCount(commentCount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Optimized Bookmark Button - Prevents parent rebuild
class BookmarkButtonOptimized extends StatefulWidget {
  final String listingId;
  final DatabaseService db;

  const BookmarkButtonOptimized({
    super.key,
    required this.listingId,
    required this.db,
  });

  @override
  State<BookmarkButtonOptimized> createState() =>
      _BookmarkButtonOptimizedState();
}

class _BookmarkButtonOptimizedState extends State<BookmarkButtonOptimized>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<bool>(
      stream: widget.db.isListingBookmarkedStream(widget.listingId),
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;
        return InkWell(
          onTap: () async {
            try {
              await widget.db.toggleBookmark(widget.listingId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          isBookmarked ? Icons.bookmark_border : Icons.bookmark,
                          color: Colors.white,
                          size: 20,
                        ),
                        Text(
                          isBookmarked
                              ? ' Removed from bookmarks'
                              : ' Added to bookmarks',
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor:
                        isBookmarked ? Colors.grey[700] : AppColors.primary,
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? AppColors.primary : Colors.black,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}

/// Post Price and Title Widget
class PostPriceTitle extends StatelessWidget {
  final Map<String, dynamic> listing;
  final VoidCallback onTap;

  const PostPriceTitle({
    super.key,
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 1, 12, 4),
        child: Row(
          children: [
            Text(
              '₱ ${listing['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '•',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                listing['title'] ?? 'No title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Post Tags Widget (Size and Condition)
class PostTags extends StatelessWidget {
  final Map<String, dynamic> listing;

  const PostTags({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 0, 12, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              listing['size'] ?? 'N/A',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              listing['condition'] ?? 'N/A',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Post Description Widget
class PostDescription extends StatelessWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;

  const PostDescription({
    super.key,
    required this.listing,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final description = listing['description'] ?? '';
    const maxLength = 30;

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    final isOverflowing = description.length > maxLength;

    if (isOverflowing) {
      final truncatedText = description.substring(0, maxLength);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ListingDetailPage(
                  listing: listing,
                  user: user,
                ),
              ),
            );
          },
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                height: 1.3,
                color: Colors.black87,
                fontFamily: 'SF Pro Display',
              ),
              children: [
                TextSpan(text: truncatedText),
                const TextSpan(
                  text: '... ',
                  style: TextStyle(color: Colors.grey),
                ),
                const TextSpan(
                  text: 'see more',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: 13,
          height: 1.3,
          fontFamily: 'SF Pro Display',
        ),
      ),
    );
  }
}

// ============================================================================
// LEGACY WIDGETS (kept for backward compatibility)
// ============================================================================

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
          horizontal: 10.0,
          vertical: 6.0,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Colors.black,
              size: 24,
            ),
            if (showCount && count != null && count! > 0) ...[
              const SizedBox(width: 8),
              Text(
                formatCount(count!),
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
}

/// Like button with stream builder (Legacy)
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
            final likeCount =
                listingSnapshot.data?['likes'] ?? initialLikeCount;

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

/// Comment button with stream builder (Legacy)
class CommentButton extends StatelessWidget {
  final String listingId;
  final DatabaseService db; // Keeping for signature compatibility
  final VoidCallback onTap;

  // Instance for the stream
  final CommentService _commentService = CommentService();

  CommentButton({
    super.key,
    required this.listingId,
    required this.db,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      // FIXED: Corrected the stream reference to the service instance
      stream: _commentService.getCommentCountStream(listingId),
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

/// Bookmark button with stream builder (Legacy)
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

/// User info header for listings (Legacy)
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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                UserAvatar(username: username, radius: 18),
                const SizedBox(width: 15),
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
                    const SizedBox(height: 4),
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

/// Listing image display (Legacy)
class ListingImage extends StatelessWidget {
  final List<dynamic>? imageUrls;
  final double height;

  const ListingImage({
    super.key,
    required this.imageUrls,
    this.height = 350,
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

/// Listing details section (Legacy)
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
        const SizedBox(height: 10),
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
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            listing['description'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
