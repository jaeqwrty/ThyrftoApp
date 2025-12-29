import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/commonWidgets/empty_state.dart';
import 'package:thryfto/commonWidgets/error.dart';
import 'package:thryfto/pages/edit_profile_page.dart';
import 'package:thryfto/profileWidgets/profile_widgets.dart';
import 'package:thryfto/services/auth_service.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/location_service.dart';
import 'package:thryfto/services/seeding_service.dart';
import 'package:thryfto/shared/auth_wrapper.dart';
import 'package:thryfto/pages/set_location_page.dart';

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
  final LocationService _locationService = LocationService();
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

  // If profile was updated, refresh the entire user data
  if (result == true && mounted) {
    // Reload user data from Firestore
    final userId = widget.user['id'] ?? widget.user['uid'] ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final updatedUser = await _authService.getUserProfile(userId);
      if (updatedUser != null && mounted) {
        // Update the user data and rebuild
        setState(() {
          // Merge the updated data with existing user data
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
        children: [
          // Profile Header
          ProfileHeader(
            user: widget.user,
            onEditProfile: _handleEditProfile,
          ),
          
          // Tab Bar
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
          // Tab Content
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
                  applicationLegalese: '© 2024 Thryfto. All rights reserved.',
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
              title: 'Reset & Re-seed Database',
              subtitle: 'Clears all listings and re-seeds (Dev Only)',
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
        const SnackBar(content: Text('Resetting and re-seeding database...')),
      );
      await SeedingService().clearAllData();
      await SeedingService().seedDatabase(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Database reset and seeded successfully!')),
        );
      }
    }
  }
}