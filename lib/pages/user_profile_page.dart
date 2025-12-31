import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/profileWidgets/profile_dialogs.dart';
import 'package:thryfto/profileWidgets/user_profileWidgets.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/favorite_service.dart';
import 'package:thryfto/services/location_service.dart';
import 'package:thryfto/services/rating_service.dart';
import 'package:thryfto/services/notification_service.dart';
import 'package:thryfto/pages/conversation_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> currentUser;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.currentUser,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final DatabaseService _db = DatabaseService();
  final LocationService _locationService = LocationService();
  final FavoritesService _favoritesService = FavoritesService();
  final RatingService _ratingService = RatingService();
  final NotificationService _notificationService = NotificationService();

  bool get _isOwnProfile {
    final currentUserId = widget.currentUser['id'] ??
        widget.currentUser['uid'] ??
        FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // CRITICAL FIX: Prevent overflow when keyboard appears
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _db.getUserProfileStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!;
          final profileImageUrl = userData['profileImageUrl'] as String?;
          final fullName =
              userData['fullName'] ?? userData['full_name'] ?? 'User';
          final username = userData['username'] ?? 'unknown';
          final bio = userData['bio'] as String?;
          final displayBio =
              (bio == null || bio.trim().isEmpty) ? 'No bio' : bio;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header Section - Wrapped in SingleChildScrollView to prevent overflow
              SingleChildScrollView(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF8B5CF6),
                            backgroundImage: (profileImageUrl != null &&
                                    profileImageUrl.isNotEmpty)
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: (profileImageUrl == null ||
                                    profileImageUrl.isEmpty)
                                ? Text(
                                    fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '@$username',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 8),
                                LocationWidget(
                                  userId: widget.userId,
                                  locationService: _locationService,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Bio
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          displayBio,
                          style: TextStyle(
                            fontSize: 15,
                            color: (bio == null || bio.trim().isEmpty)
                                ? Colors.grey[500]
                                : Colors.black87,
                            fontStyle: (bio == null || bio.trim().isEmpty)
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rating Widget
                      _RatingDisplayWidget(
                        userId: widget.userId,
                        ratingService: _ratingService,
                      ),
                      const SizedBox(height: 10),
                      // Action Buttons
                      if (!_isOwnProfile)
                        StreamBuilder<bool>(
                          stream: _favoritesService.getFavoriteStatusStream(widget.userId),
                          builder: (context, snapshot) {
                            final isFavorite = snapshot.data ?? false;
                            return ProfileActionButtons(
                              isFavorite: isFavorite,
                              onToggleFavorite: () => _toggleFavorite(isFavorite, fullName),
                              onMessage: () => _handleMessage(fullName),
                              onRate: () => _handleRating(fullName),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F7)),
              // Listings Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Listings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _db.getUserListings(widget.userId),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        final label = count == 1 ? 'item' : 'items';
                        return Text(
                          '$count $label',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Listings Grid
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getUserListings(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final listings = snapshot.data ?? [];
                    if (listings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No listings yet',
                                style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) => ListingCard(
                        listing: listings[index],
                        currentUser: widget.currentUser,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleFavorite(bool isFavorite, String sellerName) async {
    if (isFavorite) {
      final success = await _favoritesService.removeFromFavorites(widget.userId);
      if (success && mounted) {
        _showSnackBar(
          message: 'Notifications turned off',
          icon: Icons.notifications_off,
          backgroundColor: Colors.grey[700]!,
        );
      }
    } else {
      final success = await _favoritesService.addToFavorites(widget.userId);
      if (success && mounted) {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final currentUserName = widget.currentUser['fullName'] ?? 
                                widget.currentUser['full_name'] ?? 
                                'Someone';
        
        await _notificationService.createNotification(
          recipientId: widget.userId,
          type: 'follow',
          title: 'New Follower',
          body: '$currentUserName started following you',
          relatedUserId: currentUserId,
        );

        _showSnackBar(
          message: 'Following! You\'ll get notified of new listings',
          icon: Icons.check_circle,
          backgroundColor: const Color(0xFF8B5CF6),
        );
      }
    }
  }

  Future<void> _handleMessage(String fullName) async {
    final chatId = await _db.getOrCreateChat(widget.userId);
    if (chatId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationPage(
            chatId: chatId,
            otherUserId: widget.userId,
            otherUserName: fullName,
            currentUser: widget.currentUser,
          ),
        ),
      );
    }
  }

  Future<void> _handleRating(String sellerName) async {
    final result = await RatingDialog.show(
      context: context,
      userId: widget.userId,
      sellerName: sellerName,
      currentUser: widget.currentUser,
      ratingService: _ratingService,
      notificationService: _notificationService,
    );

    if (result == true && mounted) {
      _showSnackBar(
        message: 'Rating submitted successfully!',
        icon: Icons.check_circle,
        backgroundColor: Colors.green,
      );
    }
  }

  void _showSnackBar({
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Separate StatefulWidget for Rating Display
class _RatingDisplayWidget extends StatefulWidget {
  final String userId;
  final RatingService ratingService;

  const _RatingDisplayWidget({
    required this.userId,
    required this.ratingService,
  });

  @override
  State<_RatingDisplayWidget> createState() => _RatingDisplayWidgetState();
}

class _RatingDisplayWidgetState extends State<_RatingDisplayWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.ratingService.getSellerRatingStatsStream(widget.userId),
      initialData: const {
        'average_rating': 0.0,
        'ratings_count': 0,
      },
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'average_rating': 0.0,
          'ratings_count': 0,
        };
        
        final averageRating = stats['average_rating'] as double;
        final ratingsCount = stats['ratings_count'] as int;

        return GestureDetector(
          onTap: ratingsCount > 0 
              ? () => RatingsBottomSheet.show(
                    context: context,
                    userId: widget.userId,
                    ratingService: widget.ratingService,
                  )
              : null,
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