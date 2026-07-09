import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/utils/common_modals.dart';
import 'package:thryfto/shared/widgets/empty_state.dart';
import 'package:thryfto/features/profile/widgets/profile_dialogs.dart';
import 'package:thryfto/features/profile/widgets/user_profileWidgets.dart';
import 'package:thryfto/features/profile/widgets/profile_settings_handler.dart';
import 'package:thryfto/features/profile/widgets/profile_stat_column.dart';
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

  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _page = Color(0xFFF6F3F8);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _accent = Color(0xFFA8752A);

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
            backgroundColor: _page,
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
          backgroundColor: _page,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '@$username',
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              if (!_isOwnProfile)
                _buildRoundIconButton(
                  icon: Icons.more_horiz_rounded,
                  onPressed: () =>
                      _showProfileMenu(widget.userId, username, fullName),
                ),
              const SizedBox(width: 12),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                child: _buildProfileHeader(
                  fullName: fullName,
                  username: username,
                  profileImageUrl: profileImageUrl,
                  displayBio: displayBio,
                ),
              ),
              if (!_isOwnProfile)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: _buildPublicActions(fullName),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(14, _isOwnProfile ? 0 : 2, 14, 8),
                child: Row(
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 18, color: _ink),
                    const SizedBox(width: 8),
                    const Text(
                      'Listings',
                      style: TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isOwnProfile ? 'Your items' : 'Seller items',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
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
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
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
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader({
    required String fullName,
    required String username,
    required String? profileImageUrl,
    required String displayBio,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(fullName, profileImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@$username',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            displayBio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              height: 1.28,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileInfoPill(
                child: LocationWidget(
                  userId: widget.userId,
                  locationService: _locationService,
                ),
              ),
              _CompactRatingDisplay(
                userId: widget.userId,
                ratingService: _ratingService,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getUserListings(widget.userId),
                  builder: (context, s) => ProfileStatColumn(
                    value: '${s.data?.length ?? 0}',
                    label: 'posts',
                    modern: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<int>(
                  stream:
                      _favoritesService.getFavoritesCountStream(widget.userId),
                  builder: (context, s) => ProfileStatColumn(
                    value: '${s.data ?? 0}',
                    label: 'followers',
                    modern: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('favorites')
                      .where('user_id', isEqualTo: widget.userId)
                      .snapshots(),
                  builder: (context, s) => ProfileStatColumn(
                    value: '${s.data?.docs.length ?? 0}',
                    label: 'following',
                    modern: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String fullName, String? profileImageUrl) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    return Container(
      width: 68,
      height: 68,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _accent.withValues(alpha: 0.55)),
      ),
      child: CircleAvatar(
        backgroundColor: _surface,
        backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
            ? NetworkImage(profileImageUrl)
            : null,
        child: (profileImageUrl == null || profileImageUrl.isEmpty)
            ? Text(
                initial,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildPublicActions(String fullName) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<bool>(
            stream: _favoritesService.getFavoriteStatusStream(widget.userId),
            builder: (context, favSnapshot) {
              final isFavorite = favSnapshot.data ?? false;
              return _buildProfileButton(
                text: isFavorite ? 'Following' : 'Follow',
                icon: isFavorite
                    ? Icons.notifications_active_outlined
                    : Icons.person_add_alt_1_outlined,
                isPrimary: !isFavorite,
                onTap: () => _toggleFavorite(isFavorite, fullName),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildProfileButton(
            text: 'Message',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => _handleMessage(fullName),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 50,
          child: _buildProfileButton(
            icon: Icons.star_border_rounded,
            onTap: () => _handleRating(fullName),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileButton({
    String? text,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: text == null
            ? const SizedBox.shrink()
            : Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? _ink : Colors.white,
          foregroundColor: isPrimary ? Colors.white : _ink,
          elevation: 0,
          side: BorderSide(color: isPrimary ? _ink : _line),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: text == null
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: _ink, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _line),
        ),
      ),
    );
  }

  void _showProfileMenu(String userId, String username, String fullName) async {
    // Get current block status with error handling
    bool isBlocked = false;
    try {
      isBlocked = await _blockService.isUserBlockedStream(userId).first;
    } catch (_) {
      isBlocked = false;
    }

    // Check if widget is still mounted after async operation
    if (!mounted) return;

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

class _ProfileInfoPill extends StatelessWidget {
  final Widget child;

  const _ProfileInfoPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _UserProfilePageState._surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _UserProfilePageState._line),
      ),
      child: child,
    );
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
        if (stats['ratings_count'] == 0) {
          return const _ProfileInfoPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_border_rounded,
                  size: 15,
                  color: _UserProfilePageState._muted,
                ),
                SizedBox(width: 5),
                Text(
                  'No ratings',
                  style: TextStyle(
                    color: _UserProfilePageState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }

        return InkWell(
          onTap: () => RatingsBottomSheet.show(
              context: context, userId: userId, ratingService: ratingService),
          borderRadius: BorderRadius.circular(999),
          child: _ProfileInfoPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  (stats['average_rating'] as double).toStringAsFixed(1),
                  style: const TextStyle(
                    color: _UserProfilePageState._ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ' (${stats['ratings_count']})',
                  style: const TextStyle(
                    color: _UserProfilePageState._muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
