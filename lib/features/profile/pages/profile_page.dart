import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/shared/widgets/empty_state.dart';
import 'package:thryfto/features/profile/pages/edit_profile_page.dart';
import 'package:thryfto/features/profile/pages/user_follow_page.dart';
import 'package:thryfto/features/profile/widgets/profile_dialogs.dart';
import 'package:thryfto/features/profile/widgets/profile_widgets.dart';
import 'package:thryfto/features/profile/widgets/profile_settings_handler.dart';
import 'package:thryfto/features/profile/widgets/user_profileWidgets.dart';
import 'package:thryfto/features/profile/widgets/profile_stat_column.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/services/rating_service.dart';
import 'package:thryfto/core/services/favorite_service.dart';
import 'package:thryfto/core/services/location_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const ProfilePage({super.key, required this.user});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final FavoritesService _favoritesService = FavoritesService();
  final RatingService _ratingService = RatingService();
  final LocationService _locationService = LocationService();
  late TabController _tabController;

  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _page = Color(0xFFF6F3F8);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _accent = Color(0xFFA8752A);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.user['id'] ??
        widget.user['uid'] ??
        FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> userData = widget.user;
        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
        }

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
            centerTitle: false,
            titleSpacing: 20,
            title: Text(
              '@$username',
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              _buildRoundIconButton(
                icon: Icons.menu_rounded,
                onPressed: () => ProfileSettingsHandler.showSettingsMenu(
                  context: context,
                  ref: ref,
                  user: userData,
                ),
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
                  userId: userId!,
                  userData: userData,
                  fullName: fullName,
                  username: username,
                  profileImageUrl: profileImageUrl,
                  displayBio: displayBio,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        text: 'Edit Profile',
                        icon: Icons.edit_outlined,
                        isPrimary: true,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                              user: userData,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        text: 'Share',
                        icon: Icons.ios_share_outlined,
                        onTap: () => ProfileSettingsHandler.handleShareProfile(
                          context: context,
                          userId: userId,
                          username: username,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: _muted,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 2),
                      icon: Icon(Icons.grid_view_rounded, size: 18),
                      text: 'Listings',
                    ),
                    Tab(
                      iconMargin: EdgeInsets.only(bottom: 2),
                      icon: Icon(Icons.bookmark_border_rounded, size: 19),
                      text: 'Saved',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyListings(userId),
                    _buildBookmarks(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader({
    required String userId,
    required Map<String, dynamic> userData,
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
                  userId: userId,
                  locationService: _locationService,
                ),
              ),
              _CompactRatingDisplay(
                userId: userId,
                ratingService: _ratingService,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getUserListings(userId),
                  builder: (context, s) => ProfileStatColumn(
                    value: '${s.data?.length ?? 0}',
                    label: 'posts',
                    modern: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserListPage(
                        title: 'Followers',
                        userStream:
                            _favoritesService.getFollowersProfiles(userId),
                        currentUser: userData,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: StreamBuilder<int>(
                    stream: _favoritesService.getFavoritesCountStream(userId),
                    builder: (context, s) => ProfileStatColumn(
                      value: '${s.data ?? 0}',
                      label: 'followers',
                      modern: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserListPage(
                        title: 'Following',
                        userStream:
                            _favoritesService.getFollowingProfiles(userId),
                        currentUser: userData,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('favorites')
                        .where('user_id', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, s) => ProfileStatColumn(
                      value: '${s.data?.docs.length ?? 0}',
                      label: 'following',
                      modern: true,
                    ),
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

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
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

  Widget _buildMyListings(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUserListings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const EmptyState(
              icon: Icons.grid_on,
              title: 'No listings yet',
              subtitle: 'Items you post will appear here');
        }
        return ListingsGrid(listings: listings, user: widget.user);
      },
    );
  }

  Widget _buildBookmarks() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getBookmarkedListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final listings = snapshot.data ?? [];
        if (listings.isEmpty) {
          return const EmptyState(
              icon: Icons.bookmark_outline,
              title: 'No saved items',
              subtitle: 'Items you save will appear here');
        }
        return ListingsGrid(
            listings: listings, user: widget.user, showBookmarkBadge: true);
      },
    );
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
        color: _ProfilePageState._surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _ProfilePageState._line),
      ),
      child: child,
    );
  }
}

/// Compact Rating Display
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
                Icon(Icons.star_border_rounded,
                    size: 15, color: _ProfilePageState._muted),
                SizedBox(width: 5),
                Text(
                  'No ratings',
                  style: TextStyle(
                    color: _ProfilePageState._muted,
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
                    color: _ProfilePageState._ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ' (${stats['ratings_count']})',
                  style: const TextStyle(
                    color: _ProfilePageState._muted,
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
