import 'package:flutter/material.dart';
import 'package:thryfto/pages/conversation_page.dart';
import 'package:thryfto/pages/user_profile_page.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/pages/edit_listing_page.dart';
import 'package:thryfto/modals/share_modal.dart';
import 'package:thryfto/services/location_service.dart';

class ListingDetailPage extends StatefulWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;

  const ListingDetailPage({
    super.key,
    required this.listing,
    required this.user,
  });

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  final DatabaseService _db = DatabaseService();
  int _currentImageIndex = 0;
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInteractionStatus();
  }

  Future<void> _loadInteractionStatus() async {
    final listingId = widget.listing['id'];
    if (listingId != null) {
      try {
        final liked = await _db.isListingLiked(listingId);
        final bookmarked = await _db.isListingBookmarked(listingId);
        if (mounted) {
          setState(() {
            _isLiked = liked;
            _isBookmarked = bookmarked;
          });
        }
        print(
            'Loaded interaction status - Liked: $liked, Bookmarked: $bookmarked');
      } catch (e) {
        print('Error loading interaction status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = (widget.listing['image_urls'] as List<dynamic>?) ?? [];
    final hasImages = imageUrls.isNotEmpty;
    final isOwnListing = widget.listing['seller_id'] == _db.currentUserId;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.black87),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ShareModal(listing: widget.listing),
                  );
                },
              ),
              // ---- Bookmark ---
              StreamBuilder<bool>(
                stream:
                    _db.isListingBookmarkedStream(widget.listing['id'] ?? ''),
                initialData: _isBookmarked,
                builder: (context, snapshot) {
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: _isBookmarked
                            ? const Color(0xFF8B5CF6)
                            : Colors.black87,
                      ),
                    ),
                    onPressed: () async {
                      final listingId = widget.listing['id'];
                      print('Bookmark button tapped! Listing ID: $listingId');
                      print('Current bookmark state: $_isBookmarked');

                      if (listingId != null) {
                        try {
                          await _db.toggleBookmark(listingId);

                          // Update local state
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                          });

                          print(
                              'Bookmark toggled successfully! New state: $_isBookmarked');

                          if (mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      _isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isBookmarked
                                          ? 'Added to bookmarks'
                                          : 'Removed from bookmarks',
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: _isBookmarked
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.grey[700],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Error toggling bookmark: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to bookmark: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: hasImages
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: imageUrls.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(),
                            );
                          },
                        ),
                        if (imageUrls.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                imageUrls.length,
                                (index) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == index
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Like
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱ ${widget.listing['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      StreamBuilder<bool>(
                        stream: _db
                            .isListingLikedStream(widget.listing['id'] ?? ''),
                        initialData: _isLiked,
                        builder: (context, likeSnapshot) {
                          final isLiked = likeSnapshot.data ?? _isLiked;

                          return StreamBuilder<Map<String, dynamic>?>(
                            stream: _db
                                .getListingStream(widget.listing['id'] ?? ''),
                            builder: (context, listingSnapshot) {
                              final currentLikes =
                                  listingSnapshot.data?['likes'] ?? _likeCount;

                              return Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked ? Colors.red : Colors.grey,
                                      size: 28,
                                    ),
                                    onPressed: () async {
                                      final listingId = widget.listing['id'];
                                      if (listingId != null) {
                                        await _db.toggleLikeWithNotification(
                                            listingId);
                                      }
                                    },
                                  ),
                                  Text(
                                    '$currentLikes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    widget.listing['title'] ?? 'No title',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(widget.listing['size'] ?? 'N/A',
                          Colors.purple.shade50, const Color(0xFF8B5CF6)),
                      _buildTag(widget.listing['condition'] ?? 'N/A',
                          Colors.green.shade50, Colors.green.shade700),
                      _buildTag(widget.listing['category'] ?? 'Other',
                          Colors.blue.shade50, Colors.blue.shade700),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.listing['description'] ??
                        'No description available.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
// Replace the "Seller Info" section in your listing_detail_page.dart with this:

// Seller Info
                  const Text(
                    'Seller',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _db.getUserProfile(widget.listing['seller_id']),
                    builder: (context, sellerSnapshot) {
                      final seller = sellerSnapshot.data;
                      final sellerName = widget.listing['seller_name'] ??
                          seller?['username'] ??
                          'Unknown Seller';
                      final profileImageUrl =
                          seller?['profileImageUrl'] as String?;

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: LocationService()
                            .getUserLocation(widget.listing['seller_id']),
                        builder: (context, locationSnapshot) {
                          String locationDisplay = 'Location not set';

                          if (locationSnapshot.hasData &&
                              locationSnapshot.data != null) {
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
                              final sellerId = widget.listing['seller_id'];
                              if (sellerId != null) {
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
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      // Profile Avatar with Image
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor:
                                            const Color(0xFF8B5CF6),
                                        backgroundImage:
                                            (profileImageUrl != null &&
                                                    profileImageUrl.isNotEmpty)
                                                ? NetworkImage(profileImageUrl)
                                                : null,
                                        child: (profileImageUrl == null ||
                                                profileImageUrl.isEmpty)
                                            ? Text(
                                                sellerName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sellerName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on_outlined,
                                                    size: 14,
                                                    color: Colors.grey[500]),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    locationDisplay,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[500],
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_right,
                                          color: Colors.grey[400]),
                                    ],
                                  ),

                                  // Show distance if available
                                  FutureBuilder<String?>(
                                    future:
                                        LocationService().getDistanceToListing(
                                      userId: _db.currentUserId ?? '',
                                      listing: widget.listing,
                                    ),
                                    builder: (context, distanceSnapshot) {
                                      if (distanceSnapshot.hasData &&
                                          distanceSnapshot.data != null) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B5CF6)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: const Color(0xFF8B5CF6)
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.near_me,
                                                size: 16,
                                                color: Color(0xFF8B5CF6),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                distanceSnapshot.data!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF8B5CF6),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Button
      bottomNavigationBar: !isOwnListing
          ? Container(
              padding: const EdgeInsets.all(16),
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
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final chatId =
                        await _db.getOrCreateChat(widget.listing['seller_id']);
                    if (chatId != null && mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConversationPage(
                            chatId: chatId,
                            otherUserId: widget.listing['seller_id'],
                            otherUserName:
                                widget.listing['seller_name'] ?? 'Seller',
                            currentUser: widget.user,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text(
                    'Message Seller',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
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
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditListingPage(
                                listing: widget.listing,
                                user: widget.user,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            Navigator.pop(
                                context); // Go back to refresh listing
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFF8B5CF6)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleDelete(),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
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
        child: Icon(Icons.image, size: 80, color: Colors.grey[400]),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
            'Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final listingId = widget.listing['id'];
      if (listingId != null) {
        final success = await _db.deleteListing(listingId);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listing deleted successfully')),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete listing')),
            );
          }
        }
      }
    }
  }
}
