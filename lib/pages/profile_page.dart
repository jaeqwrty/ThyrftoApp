import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/commonWidgets/empty_state.dart';
import 'package:thryfto/pages/edit_profile_page.dart';
import 'package:thryfto/pages/user_follow_page.dart';
import 'package:thryfto/profileWidgets/profile_dialogs.dart';
import 'package:thryfto/profileWidgets/profile_widgets.dart';
import 'package:thryfto/profileWidgets/profile_settings_handler.dart';
import 'package:thryfto/profileWidgets/user_profileWidgets.dart';
import 'package:thryfto/services/auth_service.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/rating_service.dart';
import 'package:thryfto/services/favorite_service.dart';
import 'package:thryfto/services/location_service.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  final FavoritesService _favoritesService = FavoritesService();
  final RatingService _ratingService = RatingService();
  final LocationService _locationService = LocationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final fullName =
        widget.user['fullName'] ?? widget.user['full_name'] ?? 'User';
    final username = widget.user['username'] ?? 'unknown';
    final profileImageUrl = widget.user['profileImageUrl'] as String?;
    final bio = widget.user['bio'] as String?;
    final displayBio = (bio == null || bio.trim().isEmpty) ? 'No bio' : bio;
    final userId = widget.user['id'] ??
        widget.user['uid'] ??
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(username,
            style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => ProfileSettingsHandler.showSettingsMenu(
              context: context,
              authService: _authService,
              user: widget.user,
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header: Avatar + (Name & Stats) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      (profileImageUrl != null && profileImageUrl.isNotEmpty)
                          ? NetworkImage(profileImageUrl)
                          : null,
                  child: (profileImageUrl == null || profileImageUrl.isEmpty)
                      ? Text(fullName[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.black, fontSize: 28))
                      : null,
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _db.getUserListings(userId!),
                            builder: (context, s) => _buildStatColumn(
                                '${s.data?.length ?? 0}', 'posts'),
                          ),
                          const SizedBox(width: 30),

                          // FOLLOWERS STAT (Clickable)
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserListPage(
                                  title: 'Followers',
                                  userStream: _favoritesService
                                      .getFollowersProfiles(userId),
                                  currentUser: widget
                                      .user, // IMPORTANT: Pass the current logged-in user map here
                                ),
                              ),
                            ),
                            child: StreamBuilder<int>(
                              stream: _favoritesService
                                  .getFavoritesCountStream(userId),
                              builder: (context, s) => _buildStatColumn(
                                  '${s.data ?? 0}', 'followers'),
                            ),
                          ),
                          const SizedBox(width: 30),

                          // FOLLOWING STAT (Clickable)
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserListPage(
                                  title: 'Following',
                                  userStream: _favoritesService
                                      .getFollowingProfiles(userId),
                                  currentUser: widget
                                      .user, // IMPORTANT: Pass the current logged-in user map here
                                ),
                              ),
                            ),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('favorites')
                                  .where('user_id', isEqualTo: userId)
                                  .snapshots(),
                              builder: (context, s) => _buildStatColumn(
                                  '${s.data?.docs.length ?? 0}', 'following'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Identity: Bio, Location & Compact Rating ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayBio,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 4),
                LocationWidget(
                    userId: userId!, locationService: _locationService),
                const SizedBox(height: 4),
                _CompactRatingDisplay(
                    userId: userId, ratingService: _ratingService),
              ],
            ),
          ),

          // --- Action Buttons ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                      'Edit Profile',
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(user: widget.user)))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                      'Share Profile',
                      () => ProfileSettingsHandler.handleShareProfile(
                          context: context,
                          userId: userId,
                          username: username)),
                ),
              ],
            ),
          ),

          TabBar(
            controller: _tabController,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            indicatorWeight: 1,
            tabs: const [
              Tab(icon: Icon(Icons.grid_on_sharp, size: 24)),
              Tab(icon: Icon(Icons.bookmark_border, size: 26)),
            ],
          ),

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
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onTap) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFEFEF),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMyListings(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUserListings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        final listings = snapshot.data ?? [];
        if (listings.isEmpty)
          return const EmptyState(
              icon: Icons.grid_on,
              title: 'No listings yet',
              subtitle: 'Items you post will appear here');
        return ListingsGrid(listings: listings, user: widget.user);
      },
    );
  }

  Widget _buildBookmarks() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getBookmarkedListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
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
