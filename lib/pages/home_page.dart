import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/modals/comments.dart';
import 'package:thryfto/modals/share_modal.dart';
import 'package:thryfto/pages/notification_page.dart';
import 'package:thryfto/pages/user_profile_page.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/pages/listing_detail_page.dart';
import 'package:thryfto/services/location_service.dart';
import 'package:thryfto/services/notification_service.dart';
import 'package:thryfto/shared/notification_bell.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

final NotificationService _notificationService = NotificationService();

class _HomePageState extends State<HomePage> {
  final DatabaseService _db = DatabaseService();

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: _buildHomeFeed(),
      ),
    );
  }

  Widget _buildHomeFeed() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getActiveListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var listings = snapshot.data ?? [];

        // Sort listings by distance if user has location set
        return FutureBuilder<Map<String, dynamic>?>(
          future: LocationService().getUserLocation(_db.currentUserId ?? ''),
          builder: (context, userLocationSnapshot) {
            if (userLocationSnapshot.hasData &&
                userLocationSnapshot.data != null) {
              // Check if location data exists directly or nested
              final locationData = userLocationSnapshot.data!;
              double? userLat;
              double? userLon;

              // Try to get latitude/longitude from direct fields first
              if (locationData['latitude'] != null &&
                  locationData['longitude'] != null) {
                userLat = locationData['latitude'];
                userLon = locationData['longitude'];
              }
              // If not found, try nested location object
              else if (locationData['location'] != null) {
                final nestedLocation =
                    locationData['location'] as Map<String, dynamic>;
                userLat = nestedLocation['latitude'];
                userLon = nestedLocation['longitude'];
              }

              if (userLat != null && userLon != null) {
                listings = LocationService().sortListingsByDistance(
                  listings: listings,
                  userLat: userLat,
                  userLon: userLon,
                );
              }
            }

            // Empty state - show app bar with empty message
            if (listings.isEmpty) {
              return CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No listings yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to post!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Listings exist - show app bar with listings
            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPostCard(listings[index]),
                      childCount: listings.length,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'Thryfto',
          style: GoogleFonts.righteous(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
      actions: [
        NotificationBell(
          notificationService: _notificationService,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> listing) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _db.getUserProfileStream(listing['seller_id']),
      builder: (context, userSnapshot) {
        final seller = userSnapshot.data;
        final username = seller?['username'] ??
            seller?['fullName'] ??
            seller?['full_name'] ??
            'Unknown';
        final profileImageUrl = seller?['profileImageUrl'] as String?;
        final distanceText = listing['distance_text'] as String?;

        // Get image count
        final imageUrls = listing['image_urls'] as List?;
        final imageCount = imageUrls?.length ?? 0;

        return FutureBuilder<Map<String, dynamic>?>(
          future: LocationService().getUserLocation(listing['seller_id']),
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

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListingDetailPage(
                      listing: listing,
                      user: widget.user,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final sellerId = listing['seller_id'];
                              if (sellerId != null &&
                                  sellerId != _db.currentUserId) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserProfilePage(
                                      userId: sellerId,
                                      currentUser: widget.user,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF8B5CF6),
                                  backgroundImage: (profileImageUrl != null &&
                                          profileImageUrl.isNotEmpty)
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  child: (profileImageUrl == null ||
                                          profileImageUrl.isEmpty)
                                      ? Text(
                                          username.isNotEmpty
                                              ? username[0].toUpperCase()
                                              : '?',
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
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (distanceText != null &&
                                        distanceText != 'Location unavailable')
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 11,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            distanceText,
                                            style: const TextStyle(
                                              color: Color(0xFF8B5CF6),
                                              fontSize: 11,
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
                    ),

                    // Item image with indicator
                    Stack(
                      children: [
                        Container(
                          height: 400,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: listing['image_urls'] != null &&
                                  (listing['image_urls'] as List).isNotEmpty
                              ? Image.network(
                                  listing['image_urls'][0],
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildImagePlaceholder(),
                                )
                              : _buildImagePlaceholder(),
                        ),

                        // Image count indicator (top right)
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

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          // Like button
                          StreamBuilder<bool>(
                            stream: _db.isListingLikedStream(listing['id']),
                            initialData: false,
                            builder: (context, likeSnapshot) {
                              final isLiked = likeSnapshot.data ?? false;

                              return StreamBuilder<Map<String, dynamic>?>(
                                stream: _db.getListingStream(listing['id']),
                                initialData: null,
                                builder: (context, listingSnapshot) {
                                  final likeCount =
                                      listingSnapshot.data?['likes'] ??
                                          listing['likes'] ??
                                          0;

                                  return InkWell(
                                    onTap: () async {
                                      await _db.toggleLikeWithNotification(
                                          listing['id']);
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
                                            isLiked
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isLiked
                                                ? Colors.red
                                                : Colors.black,
                                            size: 22,
                                          ),
                                          if (likeCount > 0) ...[
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatCount(likeCount),
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
                          ),

                          const SizedBox(width: 4),

                          // Comment button
                          StreamBuilder<int>(
                            stream: _db.getCommentCountStream(listing['id']),
                            builder: (context, snapshot) {
                              final commentCount = snapshot.data ?? 0;
                              return InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => CommentsModal(
                                      listingId: listing['id'],
                                      user: widget.user,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.mode_comment_outlined,
                                        size: 22,
                                      ),
                                      if (commentCount > 0) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatCount(commentCount),
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
                          ),

                          const SizedBox(width: 4),

                          // Share button
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    ShareModal(listing: listing),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Icon(
                                Icons.share,
                                size: 22,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bookmark button
                          StreamBuilder<bool>(
                            stream:
                                _db.isListingBookmarkedStream(listing['id']),
                            initialData: false,
                            builder: (context, snapshot) {
                              final isBookmarked = snapshot.data ?? false;
                              return InkWell(
                                onTap: () async {
                                  try {
                                    await _db.toggleBookmark(listing['id']);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isBookmarked
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.black,
                                    size: 22,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Price and title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: Row(
                        children: [
                          Text(
                            '₱ ${listing['price']?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B5CF6),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Size and condition
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              listing['size'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              listing['condition'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Description with "see more"
                    _buildDescription(listing),

                    const SizedBox(height: 8),

                    // Divider between posts
                    Container(
                      height: 6,
                      color: const Color(0xFFF5F5F7),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDescription(Map<String, dynamic> listing) {
    final description = listing['description'] ?? '';
    const maxLines = 2;
    const maxLength = 30;

    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textSpan = TextSpan(
            text: description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontFamily: 'SF Pro Display',
            ),
          );

          final textPainter = TextPainter(
            text: textSpan,
            maxLines: maxLines,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: constraints.maxWidth);

          final isOverflowing =
              textPainter.didExceedMaxLines || description.length > maxLength;

          if (isOverflowing) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListingDetailPage(
                      listing: listing,
                      user: widget.user,
                    ),
                  ),
                );
              },
              child: RichText(
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.black87,
                    fontFamily: 'SF Pro Display',
                  ),
                  children: [
                    TextSpan(text: description),
                    const TextSpan(
                      text: '... ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const TextSpan(
                      text: 'see more',
                      style: TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontFamily: 'SF Pro Display',
            ),
            maxLines: maxLines,
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}