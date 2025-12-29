import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/modals/comments.dart';
import 'package:thryfto/modals/share_modal.dart';
import 'package:thryfto/pages/conversation_page.dart';
import 'package:thryfto/pages/notification_page.dart';
import 'package:thryfto/pages/user_profile_page.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/pages/sell_page.dart';
import 'package:thryfto/pages/search_page.dart';
import 'package:thryfto/pages/profile_page.dart';
import 'package:thryfto/pages/listing_detail_page.dart';
import 'package:thryfto/pages/chat_page.dart';
import 'package:thryfto/services/location_service.dart';
import 'package:thryfto/services/notification_service.dart';
import 'package:thryfto/shared/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final NotificationService _notificationService = NotificationService();

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  int _selectedIndex = 0;

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SellPage(user: widget.user),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: _buildContent(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF8B5CF6),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: 'Sell',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeFeed();
      case 1:
        return SearchPage(user: widget.user);
      case 3:
        return ChatListPage(user: widget.user);
      case 4:
        return ProfilePage(user: widget.user);
      default:
        return _buildHomeFeed();
    }
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

            if (listings.isEmpty) {
              return Center(
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
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SellPage(user: widget.user),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Listing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: CustomScrollView(
                slivers: [
                  // Sticky App Bar Header
                  SliverAppBar(
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
                  ),

                  // Listings
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

  Widget _buildPostCard(Map<String, dynamic> listing) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _db.getUserProfile(listing['seller_id']),
      builder: (context, userSnapshot) {
        final seller = userSnapshot.data;
        final username =
            listing['seller_name'] ?? seller?['username'] ?? 'Unknown';
        final profileImageUrl = seller?['profileImageUrl'] as String?;

        // Get distance text if available
        final distanceText = listing['distance_text'] as String?;

        // Get seller location
        return FutureBuilder<Map<String, dynamic>?>(
          future: LocationService().getUserLocation(listing['seller_id']),
          builder: (context, locationSnapshot) {
            String locationDisplay = 'Location not set';

            if (locationSnapshot.hasData && locationSnapshot.data != null) {
              final locationData = locationSnapshot.data!;
              final address = locationData['address'] as String?;

              // Use the address from API if available
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
                    // User info header with profile image
                    Padding(
                      padding: const EdgeInsets.all(12.0),
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
                                // Profile Avatar with Image
                                CircleAvatar(
                                  radius: 18,
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
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (distanceText != null &&
                                            distanceText !=
                                                'Location unavailable') ...[
                                          const Icon(
                                            Icons.location_on,
                                            size: 12,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            distanceText,
                                            style: const TextStyle(
                                              color: Color(0xFF8B5CF6),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ] else ...[
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            locationDisplay,
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    // Item image
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
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          // Like button with count
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
                                        horizontal: 8.0,
                                        vertical: 4.0,
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
                                            size: 24,
                                          ),
                                          if (likeCount > 0) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatCount(likeCount),
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
                                },
                              );
                            },
                          ),

                          const SizedBox(width: 8),

                          // Comment button with count
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
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.mode_comment_outlined,
                                        size: 24,
                                      ),
                                      if (commentCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatCount(commentCount),
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
                            },
                          ),
                          const SizedBox(width: 8),

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
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Icon(
                                Icons.share,
                                size: 24,
                              ),
                            ),
                          ),

                          // Bookmark button (right side)
                          const Spacer(),
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
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  child: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isBookmarked
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.black,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Size and condition
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              listing['size'] ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              listing['condition'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        listing['description'] ?? '',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Message seller button
                    if (listing['seller_id'] != _db.currentUserId)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final chatId = await _db
                                  .getOrCreateChat(listing['seller_id']);
                              if (chatId != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ConversationPage(
                                      chatId: chatId,
                                      otherUserId: listing['seller_id'],
                                      otherUserName:
                                          listing['seller_name'] ?? 'Seller',
                                      currentUser: widget.user,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.send, size: 18),
                            label: const Text(
                              'Message Seller',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    // Divider between posts
                    Container(
                      height: 8,
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }
}
