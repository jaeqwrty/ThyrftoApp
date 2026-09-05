import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/shared/widgets/image_placeholder.dart';
import 'package:thryfto/shared/widgets/tag.dart';
import 'package:thryfto/shared/widgets/user_avatar.dart';
import 'package:thryfto/shared/widgets/comments_modal.dart';
import 'package:thryfto/core/services/comments_service.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/features/profile/pages/user_profile_page.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/features/listings/pages/edit_listing_page.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';
import 'package:thryfto/core/services/chat_service.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';
import 'package:thryfto/shared/widgets/share_modal.dart';

const Color _homeInk = Color(0xFF17131F);
const Color _homeMuted = Color(0xFF6B6475);
const Color _homeSurface = Color(0xFFFBFAFC);
const Color _homeLine = Color(0xFFE5DFEC);
const Color _homeAccent = Color(0xFFA8752A);

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

  const PostCard({
    super.key,
    required this.listing,
    required this.user,
    required this.db,
    required this.onBlockedUser,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String _sellerLocation(Map<String, dynamic>? seller) {
    if (seller == null) return 'Location not set';

    bool isUsable(String? value) {
      if (value == null) return false;
      final normalized = value.trim();
      return normalized.isNotEmpty &&
          !normalized.startsWith('Lat:') &&
          normalized != 'Location set' &&
          normalized != 'Location detected';
    }

    final directAddress = seller['address']?.toString();
    if (isUsable(directAddress)) return directAddress!.trim();

    final cityState = seller['cityState']?.toString();
    if (isUsable(cityState)) return cityState!.trim();

    final nestedLocation = seller['location'];
    if (nestedLocation is Map) {
      final nestedAddress = nestedLocation['address']?.toString();
      if (isUsable(nestedAddress)) return nestedAddress!.trim();
    }

    return 'Location not set';
  }

  @override
  Widget build(BuildContext context) {
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
        final locationDisplay = _sellerLocation(seller);
        final heroTag = 'home-listing-${widget.listing['id']}';

        return RepaintBoundary(
              child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: _homeLine, width: 0.7),
                  bottom: BorderSide(color: _homeLine, width: 0.7),
                ),
              ),
              child: ClipRRect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info header
                    PostUserHeader(
                      username: username,
                      profileImageUrl: profileImageUrl,
                      distanceText: distanceText,
                      locationDisplay: locationDisplay,
                      listing: widget.listing,
                      onTap: () async {
                        final sellerId = widget.listing['seller_id'];
                        if (sellerId != null &&
                            sellerId != widget.db.currentUserId) {
                          final result = await Navigator.push(
                            context,
                            AppPageRoute.fadeThrough(
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

                    // Item image (with double-tap to like and glassmorphic badges)
                    PostImage(
                      listing: widget.listing,
                      imageUrls: imageUrls,
                      imageCount: imageCount,
                      distanceText: distanceText,
                      heroTag: heroTag,
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute.fadeThrough(
                            builder: (context) => ListingDetailPage(
                              listing: widget.listing,
                              user: widget.user,
                              heroTag: heroTag,
                            ),
                          ),
                        );
                      },
                      onDoubleTapLike: () {
                        widget.db
                            .toggleLikeWithNotification(widget.listing['id']);
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
                          AppPageRoute.fadeThrough(
                            builder: (context) => ListingDetailPage(
                              listing: widget.listing,
                              user: widget.user,
                              heroTag: heroTag,
                            ),
                          ),
                        );
                      },
                    ),

                    // Description
                    PostDescription(
                      listing: widget.listing,
                      user: widget.user,
                    ),

                    const SizedBox(height: 6),

                    // Divider line before CTA row
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(
                        color: Color(0xFFF1F5F9),
                        height: 1,
                      ),
                    ),

                    // Instant Chat CTA Row
                    PostCtaRow(
                      listing: widget.listing,
                      user: widget.user,
                    ),
                  ],
                ),
              ),
            ),
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
  final Map<String, dynamic> listing;
  final VoidCallback? onTap;

  const PostUserHeader({
    super.key,
    required this.username,
    this.profileImageUrl,
    this.distanceText,
    required this.locationDisplay,
    required this.listing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: _homeAccent.withValues(alpha: 0.45)),
                  ),
                  child: CircleAvatar(
                    backgroundColor: _homeSurface,
                    backgroundImage:
                        (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                            ? NetworkImage(profileImageUrl!)
                            : null,
                    child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                        ? Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: _homeInk,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: _homeInk,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: _homeMuted,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          locationDisplay,
                          style: GoogleFonts.poppins(
                            color: _homeMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Triple dot action options button
          IconButton(
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: _homeMuted,
              size: 20,
            ),
            onPressed: () {
              // Custom bottom sheet for options
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.share_outlined,
                            color: Colors.black87),
                        title: const Text('Share Listing'),
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ShareModal(listing: listing),
                          );
                        },
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.flag_outlined, color: Colors.red),
                        title: const Text('Report Listing',
                            style: TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          SnackbarUtils.showSuccess(
                              context, 'Thank you! Listing reported.');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Post Image Widget (Stateful for double-tap animation & overlays)
class PostImage extends StatefulWidget {
  final Map<String, dynamic> listing;
  final List? imageUrls;
  final int imageCount;
  final VoidCallback onTap;
  final VoidCallback onDoubleTapLike;
  final String? distanceText;
  final String heroTag;

  const PostImage({
    super.key,
    required this.listing,
    required this.imageUrls,
    required this.imageCount,
    required this.onTap,
    required this.onDoubleTapLike,
    required this.heroTag,
    this.distanceText,
  });

  @override
  State<PostImage> createState() => _PostImageState();
}

class _PostImageState extends State<PostImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartAnimController;
  late Animation<double> _heartScale;
  late Animation<double> _heartFade;
  bool _isAnimatingHeart = false;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOutBack),
    );

    _heartFade = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  void _triggerDoubleTap() {
    widget.onDoubleTapLike();
    setState(() {
      _isAnimatingHeart = true;
    });
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimatingHeart = false;
        });
      }
    });
  }

  Widget _buildGlassBadge(String text, IconData icon) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 11),
              const SizedBox(width: 4),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.imageUrls != null && widget.imageUrls!.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: _triggerDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image render
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: const Color(0xFFF8FAFC),
              child: hasImages
                  ? Hero(
                      tag: widget.heroTag,
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls![0].toString(),
                        fit: BoxFit.cover,
                        memCacheWidth: 1200,
                        fadeInDuration: const Duration(milliseconds: 180),
                        placeholder: (context, _) => const ColoredBox(
                          color: Color(0xFFF1EDF4),
                          child: Center(child: ImagePlaceholder(size: 45)),
                        ),
                        errorWidget: (context, _, __) =>
                            const ImagePlaceholder(size: 45),
                      ),
                    )
                  : const ImagePlaceholder(size: 45),
            ),
          ),

          // Double tap heartbeat pulse heart overlay
          if (_isAnimatingHeart)
            AnimatedBuilder(
              animation: _heartAnimController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _heartScale.value,
                  child: Opacity(
                    opacity: _heartFade.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Top Floating Badges (Sold / Image Count / Distance)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top-Left Distance Tag
                if (widget.distanceText != null &&
                    widget.distanceText != 'Location unavailable')
                  _buildGlassBadge(
                      widget.distanceText!, Icons.location_on_rounded)
                else
                  const SizedBox.shrink(),

                // Top-Right Badges (Sold & Image Count)
                Row(
                  children: [
                    if (widget.listing['status'] == 'sold')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444), // Crimson Red
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          'SOLD',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (widget.listing['status'] == 'sold' &&
                        widget.imageCount > 1)
                      const SizedBox(width: 6),
                    if (widget.imageCount > 1)
                      _buildGlassBadge(
                          '${widget.imageCount}', Icons.photo_library_rounded),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Floating Glassmorphic Tags (Size & Condition)
          Positioned(
            bottom: 12,
            left: 12,
            child: Row(
              children: [
                _buildGlassBadge(
                    widget.listing['size'] ?? 'N/A', Icons.straighten_rounded),
                const SizedBox(width: 6),
                _buildGlassBadge(
                    widget.listing['condition'] ?? 'N/A', Icons.stars_rounded),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          LikeButtonOptimized(
            listingId: listingId,
            initialLikes: listing['likes'] ?? 0,
            db: db,
          ),
          const SizedBox(width: 6),
          CommentButtonOptimized(
            listingId: listingId,
            user: user,
          ),
          const SizedBox(width: 6),
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
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.ios_share_rounded, // Sleek iOS share icon
                size: 22,
                color: Color(0xFF475569),
              ),
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
    with SingleTickerProviderStateMixin {
  bool? _optimisticLiked;
  int? _optimisticCount;

  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.db.isListingLikedStream(widget.listingId),
      builder: (context, likeSnapshot) {
        final isLiked = _optimisticLiked ?? likeSnapshot.data ?? false;

        return StreamBuilder<Map<String, dynamic>?>(
          stream: widget.db.getListingStream(widget.listingId),
          builder: (context, listingSnapshot) {
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
                _bounceController.forward(from: 0.0);
                setState(() {
                  _optimisticLiked = !isLiked;
                  _optimisticCount = isLiked ? likeCount - 1 : likeCount + 1;
                });
                widget.db.toggleLikeWithNotification(widget.listingId);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF475569),
                            size: 23,
                          ),
                        );
                      },
                    ),
                    if (likeCount > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        formatCount(likeCount),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
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

class _CommentButtonOptimizedState extends State<CommentButtonOptimized> {
  final CommentService _commentService = CommentService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
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
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mode_comment_outlined,
                  size: 21,
                  color: Color(0xFF475569),
                ),
                if (hasData && commentCount > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    formatCount(commentCount),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
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

class _BookmarkButtonOptimizedState extends State<BookmarkButtonOptimized> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.db.isListingBookmarkedStream(widget.listingId),
      builder: (context, snapshot) {
        final isBookmarked = snapshot.data ?? false;
        return InkWell(
          onTap: () async {
            try {
              await widget.db.toggleBookmark(widget.listingId);
              if (mounted) {
                SnackbarUtils.showSuccess(
                  context,
                  isBookmarked
                      ? 'Removed from bookmarks'
                      : 'Added to bookmarks',
                );
              }
            } catch (e) {
              if (mounted) {
                SnackbarUtils.showError(context, 'Error: $e');
              }
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: isBookmarked ? _homeInk : _homeMuted,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '₱${listing['price']?.toStringAsFixed(2) ?? '0.00'}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _homeInk,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              listing['title'] ?? 'No title',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Post Tags Widget (Dummy to preserve legacy signature)
class PostTags extends StatelessWidget {
  final Map<String, dynamic> listing;

  const PostTags({
    super.key,
    required this.listing,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
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
    const maxLength = 60;

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    final isOverflowing = description.length > maxLength;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
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
        child: Text.rich(
          TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.45,
              color: const Color(0xFF475569), // Slate 600
            ),
            children: [
              TextSpan(
                text: isOverflowing
                    ? '${description.substring(0, maxLength)}...'
                    : description,
              ),
              if (isOverflowing)
                TextSpan(
                  text: ' see more',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Instant CTA Row (Chat / Edit) Widget
class PostCtaRow extends StatefulWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;

  const PostCtaRow({
    super.key,
    required this.listing,
    required this.user,
  });

  @override
  State<PostCtaRow> createState() => _PostCtaRowState();
}

class _PostCtaRowState extends State<PostCtaRow> {
  bool _isOpeningChat = false;

  Widget _buildChatButton() {
    return _isOpeningChat
        ? const SizedBox(
            height: 32,
            width: 32,
            child: Padding(
              padding: EdgeInsets.all(6.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          )
        : InkWell(
            onTap: _openChat,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _homeInk,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Future<void> _openChat() async {
    setState(() => _isOpeningChat = true);
    try {
      final chatService = ChatService();
      final chatId =
          await chatService.getOrCreateChat(widget.listing['seller_id']);

      if (!mounted) return;
      setState(() => _isOpeningChat = false);

      if (chatId != null) {
        Navigator.push(
          context,
          AppPageRoute.fadeThrough(
            builder: (context) => ConversationPage(
              chatId: chatId,
              otherUserId: widget.listing['seller_id'],
              otherUserName: widget.listing['seller_name'] ?? 'Seller',
              currentUser: widget.user,
            ),
          ),
        );
      } else {
        SnackbarUtils.showError(
            context, 'Failed to open chat. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOpeningChat = false);
        SnackbarUtils.showError(context, 'Error opening chat: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellerId = widget.listing['seller_id'];
    final currentUserId = widget.user['uid'];
    final isSeller = sellerId == currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left label
          Text(
            isSeller ? 'Your active listing' : 'Interested in this item?',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _homeMuted,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Right CTA button
          if (isSeller)
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  AppPageRoute.fadeThrough(
                    builder: (context) => EditListingPage(
                      listing: widget.listing,
                      user: widget.user,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _homeSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _homeLine,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: _homeInk,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Edit',
                      style: GoogleFonts.poppins(
                        color: _homeInk,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _buildChatButton(),
        ],
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
