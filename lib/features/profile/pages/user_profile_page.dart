import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/shared/widgets/empty_state.dart';
import 'package:thryfto/features/profile/widgets/profile_dialogs.dart';
import 'package:thryfto/features/profile/widgets/user_profileWidgets.dart';
import 'package:thryfto/features/profile/widgets/profile_settings_handler.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/services/chat_service.dart';
import 'package:thryfto/core/services/favorite_service.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/services/rating_service.dart';
import 'package:thryfto/core/services/notification_service.dart';
import 'package:thryfto/core/services/block_service.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';

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
  final ChatService _chatService = ChatService();
  final LocationService _locationService = LocationService();
  final FavoritesService _favoritesService = FavoritesService();
  final RatingService _ratingService = RatingService();
  final NotificationService _notificationService = NotificationService();
  final BlockService _blockService = BlockService();

  bool get _isOwnProfile {
    final currentUserId = widget.currentUser['id'] ??
        widget.currentUser['uid'] ??
        FirebaseAuth.instance.currentUser?.uid;
    return currentUserId == widget.userId;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _db.getUserProfileStream(widget.userId),
      builder: (context, snapshot) {
        // Handle initial loading state
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundWhite,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data ?? {};
        final fullName =
            userData['fullName'] ?? userData['full_name'] ?? 'User';
        final username = userData['username'] ?? 'unknown';
        final profileImageUrl = userData['profileImageUrl'] as String?;
        final bio = userData['bio'] as String?;
        final displayBio = (bio == null || bio.trim().isEmpty) ? 'No bio' : bio;

        return Scaffold(
          backgroundColor: AppColors.backgroundWhite,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(username,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon:
                    const Icon(Icons.more_horiz, color: AppColors.textPrimary),
                onPressed: () =>
                    _showProfileMenu(widget.userId, username, fullName),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section: Avatar & Stats ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: AppColors.primary,
                      backgroundImage: (profileImageUrl != null &&
                              profileImageUrl.isNotEmpty)
                          ? NetworkImage(profileImageUrl)
                          : null,
                      child:
                          (profileImageUrl == null || profileImageUrl.isEmpty)
                              ? Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                      color: AppColors.backgroundWhite,
                                      fontSize: 24))
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

              // --- Identity: Bio, Location & Rating ---
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayBio,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textPrimary)),
                    LocationWidget(
                        userId: widget.userId,
                        locationService: _locationService),
                    const SizedBox(height: 4),
                    _CompactRatingDisplay(
                        userId: widget.userId, ratingService: _ratingService),
                  ],
                ),
              ),

              // --- Action Buttons (Visible only if not own profile) ---
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
                                      ? AppColors.backgroundGreyDark
                                      : AppColors.info,
                                  foregroundColor: isFavorite
                                      ? AppColors.textPrimary
                                      : AppColors.backgroundWhite,
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

              // --- Grid Label ---
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.grid_on, size: 18),
                    SizedBox(width: 8),
                    Text('Listings',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),

              // --- Listings Grid ---
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getUserListings(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final listings = snapshot.data ?? [];

                    // Show empty state when there are no listings
                    if (listings.isEmpty) {
                      return EmptyState(
                        icon: Icons.storefront_outlined,
                        title: _isOwnProfile
                            ? 'No listings yet'
                            : 'No listings available',
                        subtitle: _isOwnProfile
                            ? 'Start selling by creating your first listing'
                            : 'This seller has no active listings at the moment',
                      );
                    }

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

  void _showProfileMenu(String userId, String username, String fullName) async {
    // Get current block status
    final isBlocked = await _blockService.isUserBlockedStream(userId).first;

    CommonModals.showOptionsModal(
      context,
      title: 'Profile Options',
      items: [
        OptionsModalItem(
          icon: Icons.share_outlined,
          iconColor: AppColors.primary,
          iconBackgroundColor: AppColors.primary,
          title: 'Share Profile',
          onTap: () {
            ProfileSettingsHandler.handleShareProfile(
              context: context,
              userId: userId,
              username: username,
            );
          },
        ),
        // Dynamic block/unblock item
        OptionsModalItem(
          icon: isBlocked ? Icons.block : Icons.block_outlined,
          iconColor: AppColors.error,
          iconBackgroundColor: AppColors.error,
          title: isBlocked ? 'Unblock User' : 'Block User',
          onTap: () {
            if (isBlocked) {
              _handleUnblock(userId, fullName);
            } else {
              _handleBlock(userId, fullName);
            }
          },
        ),
      ],
    );
  }

  void _handleBlock(String userId, String userName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block $userName?\n\n'
          'They won\'t be able to:\n'
          '• Follow you or see your posts\n'
          '• Message you\n'
          '• See your profile\n\n'
          'You won\'t see their content either.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.pop(dialogContext);

              // Show loading indicator
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.backgroundWhite),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Blocking user...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              final success = await _blockService.blockUser(userId);

              if (!mounted) return;

              // Clear the loading snackbar
              ScaffoldMessenger.of(context).clearSnackBars();

              // Pop the current page and pass result back
              Navigator.of(context).pop(success ? 'blocked' : null);

              // Show result snackbar on the previous page
              if (success) {
                await Future.delayed(const Duration(milliseconds: 100));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.block,
                              color: AppColors.backgroundWhite, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('$userName has been blocked')),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } else {
                await Future.delayed(const Duration(milliseconds: 100));

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: AppColors.backgroundWhite, size: 20),
                          SizedBox(width: 8),
                          Expanded(child: Text('Failed to block user')),
                        ],
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Block',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUnblock(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock $userName? '
          'They will be able to follow you and message you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await _blockService.unblockUser(userId);

              if (success && mounted) {
                _showSnackBar(
                  message: '$userName has been unblocked',
                  icon: Icons.check_circle,
                  backgroundColor: Colors.green,
                );
              } else if (mounted) {
                _showSnackBar(
                  message: 'Failed to unblock user',
                  icon: Icons.error_outline,
                  backgroundColor: AppColors.error,
                );
              }
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
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
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
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
          backgroundColor: AppColors.backgroundGreyDark,
          foregroundColor: AppColors.textPrimary,
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
            message: 'Unfollowed $sellerName',
            icon: Icons.notifications_off,
            backgroundColor: AppColors.textSecondary);
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
            backgroundColor: AppColors.primary);
      }
    }
  }

  Future<void> _handleMessage(String fullName) async {
    if (!mounted) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.backgroundWhite),
              ),
            ),
            SizedBox(width: 12),
            Text('Opening chat...'),
          ],
        ),
        duration: Duration(seconds: 1),
      ),
    );

    // Get or create chat - this ensures only one chat per user pair
    final chatId = await _chatService.getOrCreateChat(widget.userId);

    if (!mounted) return;

    // Clear loading message
    ScaffoldMessenger.of(context).clearSnackBars();

    if (chatId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationPage(
            chatId: chatId, // Always provide chat ID
            otherUserId: widget.userId,
            otherUserName: fullName,
            currentUser: widget.currentUser,
          ),
        ),
      );
    } else {
      _showSnackBar(
        message: 'Failed to open chat. Please try again.',
        icon: Icons.error_outline,
        backgroundColor: AppColors.error,
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
          Icon(icon, color: AppColors.backgroundWhite, size: 20),
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
