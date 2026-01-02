import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/global/app_colors.dart';
import 'package:thryfto/homeWidgets/home_widgets.dart';
import 'package:thryfto/pages/notification_page.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/block_service.dart';
import 'package:thryfto/services/favorite_service.dart'; // Added
import 'package:thryfto/services/notification_service.dart';
import 'package:thryfto/shared/notification_bell.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for Timestamp comparison

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _db = DatabaseService();
  final BlockService _blockService = BlockService();
  final NotificationService _notificationService = NotificationService();
  final FavoritesService _favoritesService = FavoritesService(); // Added
  
  // Removed _userLocationFuture
  late Stream<List<String>> _followedSellersStream;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the stream of users being followed
    _followedSellersStream = _favoritesService.getFavoritedSellers();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshKey++;
      // Re-initialize the stream on refresh
      _followedSellersStream = _favoritesService.getFavoritedSellers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        // Removed the outer FutureBuilder for location
        child: _buildHomeFeed(),
      ),
    );
  }

  Widget _buildHomeFeed() {
    // 1. Get the list of followed sellers
    return StreamBuilder<List<String>>(
      stream: _followedSellersStream,
      builder: (context, followSnapshot) {
        final followedIds = followSnapshot.data ?? [];

        // 2. Get active listings
        return StreamBuilder<List<Map<String, dynamic>>>(
          key: ValueKey('feed_$_refreshKey'),
          stream: _db.getActiveListings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _refreshKey == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            var listings = snapshot.data ?? [];

            // 3. Filter blocked users
            return FutureBuilder<List<Map<String, dynamic>>>(
              key: ValueKey('filter_$_refreshKey'),
              future: _blockService.filterBlockedListings(listings),
              builder: (context, blockedFilterSnapshot) {
                var filteredListings = blockedFilterSnapshot.data ?? listings;

                // 4. SORTING LOGIC: Prioritize followed users
                filteredListings.sort((a, b) {
                  bool aFollowed = followedIds.contains(a['seller_id']);
                  bool bFollowed = followedIds.contains(b['seller_id']);

                  // If one is followed and the other isn't, followed comes first
                  if (aFollowed && !bFollowed) return -1;
                  if (!aFollowed && bFollowed) return 1;

                  // If both are followed OR both are not followed, sort by date (newest first)
                  Timestamp aTime = a['created_at'] ?? Timestamp.now();
                  Timestamp bTime = b['created_at'] ?? Timestamp.now();
                  return bTime.compareTo(aTime);
                });

                if (filteredListings.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final listing = filteredListings[index];
                            return PostCard(
                              key: ValueKey(listing['id']),
                              listing: listing,
                              user: widget.user,
                              db: _db,
                              onBlockedUser: _handleRefresh,
                            );
                          },
                          childCount: filteredListings.length,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No listings yet', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.primary, Color(0xFFD946EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
        child: Text(
          'Thryfto',
          style: GoogleFonts.righteous(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
        ),
      ),
      actions: [
        NotificationBell(
          notificationService: _notificationService,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
        ),
        const SizedBox(width: 7),
      ],
    );
  }
}