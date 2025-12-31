import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/profileWidgets/profile_dialogs.dart';
import 'package:thryfto/profileWidgets/user_profileWidgets.dart';
import 'package:thryfto/profileWidgets/profile_settings_handler.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/chat_service.dart'; // Added ChatService
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
  final ChatService _chatService = ChatService(); // Added ChatService
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

  void _showProfileMenu(String userId, String username) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                ProfileSettingsHandler.handleShareProfile(
                  context: context,
                  userId: userId,
                  username: username,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined, color: Colors.red),
              title:
                  const Text('Block User', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar(
                  message: 'Block feature coming soon!',
                  icon: Icons.info_outline,
                  backgroundColor: Colors.black87,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _db.getUserProfileStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final userData = snapshot.data ?? {};
        final fullName =
            userData['fullName'] ?? userData['full_name'] ?? 'User';
        final username = userData['username'] ?? 'unknown';
        final profileImageUrl = userData['profileImageUrl'] as String?;
        final bio = userData['bio'] as String?;
        final displayBio = (bio == null || bio.trim().isEmpty) ? 'No bio' : bio;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(username,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.black),
                onPressed: () => _showProfileMenu(widget.userId, username),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFF8B5CF6),
                      backgroundImage: (profileImageUrl != null &&
                              profileImageUrl.isNotEmpty)
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child:
                          (profileImageUrl == null || profileImageUrl.isEmpty)
                              ? Text(fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 24))
                              : null,
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _db.getUserListings(widget.userId),
                                builder: (context, s) => _buildStatColumn(
                                    '${s.data?.length ?? 0}', 'posts'),
                              ),
                              const SizedBox(width: 30),
                              StreamBuilder<int>(
                                stream: _favoritesService
                                    .getFavoritesCountStream(widget.userId),
                                builder: (context, s) => _buildStatColumn(
                                    '${s.data ?? 0}', 'followers'),
                              ),
                              const SizedBox(width: 30),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('favorites')
                                    .where('user_id', isEqualTo: widget.userId)
                                    .snapshots(),
                                builder: (context, s) => _buildStatColumn(
                                    '${s.data?.docs.length ?? 0}', 'following'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayBio,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                    LocationWidget(
                        userId: widget.userId,
                        locationService: _locationService),
                    const SizedBox(height: 4),
                    _CompactRatingDisplay(
                        userId: widget.userId, ratingService: _ratingService),
                  ],
                ),
              ),

              if (!_isOwnProfile)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<bool>(
                          stream: _favoritesService
                              .getFavoriteStatusStream(widget.userId),
                          builder: (context, favSnapshot) {
                            final isFavorite = favSnapshot.data ?? false;
                            return SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: () =>
                                    _toggleFavorite(isFavorite, fullName),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFavorite
                                      ? Colors.grey[200]
                                      : const Color(0xFF4A69FF),
                                  foregroundColor:
                                      isFavorite ? Colors.black : Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                                child: Text(isFavorite ? 'Following' : 'Follow',
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildSecondaryButton(
                            'Message', () => _handleMessage(fullName)),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: _buildSecondaryButton(
                            null, () => _handleRating(fullName),
                            icon: Icons.star_border),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 1),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.grid_on, size: 18),
                    SizedBox(width: 8),
                    Text('Listings',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getUserListings(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    final listings = snapshot.data ?? [];
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                          currentUser: widget.currentUser),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildSecondaryButton(String? text, VoidCallback onTap,
      {IconData? icon}) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: EdgeInsets.zero,
        ),
        child: icon != null
            ? Icon(icon, size: 18)
            : Text(text!, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  Future<void> _toggleFavorite(bool isFavorite, String sellerName) async {
    if (isFavorite) {
      final success =
          await _favoritesService.removeFromFavorites(widget.userId);
      if (success && mounted) {
        _showSnackBar(
            message: 'Notifications turned off',
            icon: Icons.notifications_off,
            backgroundColor: Colors.grey[700]!);
      }
    } else {
      final success = await _favoritesService.addToFavorites(widget.userId);
      if (success && mounted) {
        await _notificationService.createNotification(
          recipientId: widget.userId,
          type: 'follow',
          title: 'New Follower',
          body:
              '${widget.currentUser['fullName'] ?? 'Someone'} started following you',
          relatedUserId: FirebaseAuth.instance.currentUser?.uid,
        );
        _showSnackBar(
            message: 'Following! You\'ll get notified of new listings',
            icon: Icons.check_circle,
            backgroundColor: const Color(0xFF8B5CF6));
      }
    }
  }

  Future<void> _handleMessage(String fullName) async {
    // FIXED: Now using ChatService instead of DatabaseService
    final chatId = await _chatService.getOrCreateChat(widget.userId);
    if (chatId != null && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ConversationPage(
                    chatId: chatId,
                    otherUserId: widget.userId,
                    otherUserName: fullName,
                    currentUser: widget.currentUser,
                  )));
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
          backgroundColor: Colors.green);
    }
  }

  void _showSnackBar(
      {required String message,
      required IconData icon,
      required Color backgroundColor}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message))
        ]),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }
}

class _CompactRatingDisplay extends StatelessWidget {
  final String userId;
  final RatingService ratingService;
  const _CompactRatingDisplay(
      {required this.userId, required this.ratingService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ratingService.getSellerRatingStatsStream(userId),
      builder: (context, snapshot) {
        final stats =
            snapshot.data ?? {'average_rating': 0.0, 'ratings_count': 0};
        if (stats['ratings_count'] == 0) return const SizedBox.shrink();

        return InkWell(
          onTap: () => RatingsBottomSheet.show(
              context: context, userId: userId, ratingService: ratingService),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text((stats['average_rating'] as double).toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              Text(' (${stats['ratings_count']})',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}