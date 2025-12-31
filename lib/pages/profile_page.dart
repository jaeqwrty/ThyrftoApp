import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/commonWidgets/empty_state.dart';
import 'package:thryfto/commonWidgets/error.dart';
import 'package:thryfto/pages/edit_profile_page.dart';
import 'package:thryfto/profileWidgets/profile_widgets.dart';
import 'package:thryfto/profileWidgets/profile_dialogs.dart';
import 'package:thryfto/services/auth_service.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/rating_service.dart';
import 'package:thryfto/services/seeding_service.dart';
import 'package:thryfto/shared/auth_wrapper.dart';

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
  final RatingService _ratingService = RatingService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      confirmColor: Colors.red,
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: widget.user),
      ),
    );

    if (result == true && mounted) {
      final userId = widget.user['id'] ?? widget.user['uid'] ?? FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final updatedUser = await _authService.getUserProfile(userId);
        if (updatedUser != null && mounted) {
          setState(() {
            widget.user.clear();
            widget.user.addAll(updatedUser);
          });
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Header (Avatar, Name, Location)
          ProfileHeader(
            user: widget.user,
            onEditProfile: () {}, 
          ),
          
          // 2. Bio Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 5),
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

          // 3. Rating Display - Using reusable widget from profile_dialogs.dart
          if (userId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _RatingDisplayWidget(
                userId: userId,
                ratingService: _ratingService,
              ),
            ),

          // 4. Edit Profile Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _handleEditProfile,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 10),

          // 5. Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B5CF6),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF8B5CF6),
              tabs: const [
                Tab(icon: Icon(Icons.grid_view), text: 'My Listings'),
                Tab(icon: Icon(Icons.bookmark_outline), text: 'Bookmarks'),
              ],
            ),
          ),
          
          // 6. Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyListings(),
                _buildBookmarks(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyListings() {
    final userId = widget.user['id'] ??
        widget.user['uid'] ??
        FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const ErrorState(message: 'Unable to load listings');
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _db.getUserListings(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return ErrorState(message: 'Error: ${snapshot.error}');
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return const EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No listings yet',
            subtitle: 'Start selling by tapping the + button',
          );
        }

        return ListingsGrid(
          listings: listings,
          user: widget.user,
        );
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

        if (snapshot.hasError) {
          return ErrorState(message: 'Error: ${snapshot.error}');
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return const EmptyState(
            icon: Icons.bookmark_outline,
            title: 'No bookmarks yet',
            subtitle: 'Save items you like for later',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListingsGrid(
            listings: listings,
            user: widget.user,
            showBookmarkBadge: true,
          ),
        );
      },
    );
  }

  void _showSettingsMenu() {
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
            SettingsMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support coming soon!')),
                );
              },
            ),
            SettingsMenuItem(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Thryfto',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 Thryfto. All rights reserved.',
                );
              },
            ),
            SettingsMenuItem(
              icon: Icons.cloud_upload,
              title: 'Seed Database (Dev Only)',
              onTap: () => _handleSeedDatabase(),
            ),
            SettingsMenuItem(
              icon: Icons.refresh,
              title: 'Reset Database',
              subtitle: 'Clears all listings (Dev Only)',
              onTap: () => _handleResetDatabase(),
            ),
            const Divider(),
            SettingsMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSeedDatabase() async {
    final userId = widget.user['id'] ??
        widget.user['uid'] ??
        FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeding database...')),
      );
      await SeedingService().seedDatabase(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database seeded successfully!')),
        );
      }
    }
  }

  Future<void> _handleResetDatabase() async {
    Navigator.pop(context);
    final userId = widget.user['id'] ??
        widget.user['uid'] ??
        FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resetting database...')),
      );
      await SeedingService().clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset successfully!')),
        );
      }
    }
  }
}

/// Separate StatefulWidget for Rating Display - Reusable across pages
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