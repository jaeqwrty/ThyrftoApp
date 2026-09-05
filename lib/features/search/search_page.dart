import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/shared/widgets/empty_state.dart';
import 'package:thryfto/shared/widgets/error.dart';
import 'package:thryfto/shared/widgets/image_placeholder.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/services/block_service.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/shared/widgets/skeleton_loaders.dart';

class SearchPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const SearchPage({super.key, required this.user});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _chip = Color(0xFFF4F1F7);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();
  final BlockService _blockService = BlockService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'none';
  String _priceSortDirection = 'low';
  String _distanceSortDirection = 'near';
  Map<String, dynamic>? _userLocation;
  Timer? _searchDebounce;
  StreamSubscription<Map<String, dynamic>?>? _userLocationSubscription;

  final List<String> _categories = [
    'All',
    'Clothing',
    'Shoewear',
    'Accessories',
    'Bags',
  ];

  @override
  void initState() {
    super.initState();
    _setupUserLocationStream(); // Changed from _loadUserLocation
  }

  Future<void> _setupUserLocationStream() async {
    try {
      final userId = widget.user['id'] ??
          widget.user['uid'] ??
          FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        // Create a stream that listens to user document changes
        final userLocationStream =
            _firestore.collection('users').doc(userId).snapshots().map((doc) {
          if (!doc.exists) return null;

          final data = doc.data();
          if (data == null) return null;

          // Check for direct latitude/longitude fields (current structure)
          if (data['latitude'] != null && data['longitude'] != null) {
            return {
              'latitude': data['latitude'],
              'longitude': data['longitude'],
              'address': data['address'],
            };
          }

          // Fall back to nested location object (old structure)
          if (data['location'] != null) {
            return data['location'] as Map<String, dynamic>;
          }

          return null;
        });

        // Listen to the stream and update state
        _userLocationSubscription = userLocationStream.listen((location) {
          if (!mounted) return;
          setState(() => _userLocation = location);
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _userLocationSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _line, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Discover',
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              Spacer(),
              Icon(Icons.tune_rounded, color: _muted, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 250), () {
                  if (mounted) {
                    setState(() => _searchQuery = value.toLowerCase());
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Search clothing, bags, shoes...',
                hintStyle: const TextStyle(color: Color(0xFF9A93A6)),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _muted, size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: _muted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return _buildCategoryChip(category, isSelected);
              },
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip('Relevance', 'none'),
                _buildPriceSortChip(),
                if (_userLocation != null) _buildDistanceSortChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        showCheckmark: false,
        avatar: category == 'All'
            ? Icon(
                Icons.grid_view_rounded,
                size: 15,
                color: isSelected ? Colors.white : _muted,
              )
            : null,
        backgroundColor: _surface,
        selectedColor: _ink,
        side: BorderSide(color: isSelected ? _ink : _line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : _muted,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      ),
    );
  }

  Widget _buildPriceSortChip() {
    final isSelected = _sortBy == 'price_low' || _sortBy == 'price_high';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Price'),
            const SizedBox(width: 4),
            Icon(
              _priceSortDirection == 'low'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: isSelected ? Colors.white : _muted,
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (isSelected) {
              _priceSortDirection =
                  _priceSortDirection == 'low' ? 'high' : 'low';
              _sortBy =
                  _priceSortDirection == 'low' ? 'price_low' : 'price_high';
            } else {
              _priceSortDirection = 'low';
              _sortBy = 'price_low';
            }
          });
        },
        backgroundColor: _chip,
        selectedColor: _ink,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : _muted,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide(color: isSelected ? _ink : _line),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildDistanceSortChip() {
    final isSelected = _sortBy == 'distance_near' || _sortBy == 'distance_far';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Distance'),
            const SizedBox(width: 4),
            Icon(
              _distanceSortDirection == 'near'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: isSelected ? Colors.white : _muted,
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (isSelected) {
              _distanceSortDirection =
                  _distanceSortDirection == 'near' ? 'far' : 'near';
              _sortBy = _distanceSortDirection == 'near'
                  ? 'distance_near'
                  : 'distance_far';
            } else {
              _distanceSortDirection = 'near';
              _sortBy = 'distance_near';
            }
          });
        },
        backgroundColor: _chip,
        selectedColor: _ink,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : _muted,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide(color: isSelected ? _ink : _line),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _sortBy = value);
        },
        backgroundColor: _chip,
        selectedColor: _ink,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : _muted,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide(color: isSelected ? _ink : _line),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildSearchResults() {
    Query<Map<String, dynamic>> query =
        _firestore.collection('listings').where('status', isEqualTo: 'active');

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListingGridSkeleton();
        }

        if (snapshot.hasError) {
          return ErrorState(message: 'Error: ${snapshot.error}');
        }

        var listings = snapshot.data?.docs ?? [];

        // Get current user ID
        final currentUserId = widget.user['id'] ??
            widget.user['uid'] ??
            FirebaseAuth.instance.currentUser?.uid;

        // Filter by search query and exclude current user's listings
        if (_searchQuery.isNotEmpty) {
          listings = listings.where((doc) {
            final data = doc.data();
            final title = (data['title'] ?? '').toString().toLowerCase();
            final description =
                (data['description'] ?? '').toString().toLowerCase();
            final sellerId = data['seller_id'] ?? data['user_id'];

            return (sellerId != currentUserId) &&
                (title.contains(_searchQuery) ||
                    description.contains(_searchQuery));
          }).toList();
        } else {
          listings = listings.where((doc) {
            final data = doc.data();
            final sellerId = data['seller_id'] ?? data['user_id'];
            return sellerId != currentUserId;
          }).toList();
        }

        // Convert to list of maps with IDs
        List<Map<String, dynamic>> listingsList = listings.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        // Filter out blocked users' listings
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _blockService.filterBlockedListings(listingsList),
          builder: (context, blockedFilterSnapshot) {
            if (blockedFilterSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const ListingGridSkeleton();
            }

            var filteredListings = blockedFilterSnapshot.data ?? listingsList;

            // REAL-TIME DISTANCE: Apply sorting with current user location
            // This recalculates whenever _userLocation changes!
            filteredListings = _applySorting(filteredListings);

            if (filteredListings.isEmpty) {
              return EmptyState(
                icon: Icons.search_off,
                title: _searchQuery.isNotEmpty
                    ? 'No results found'
                    : 'No items in this category',
                subtitle: _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : 'Check back later for new items',
              );
            }

            return GridView.builder(
              cacheExtent: 700,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 14,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredListings.length,
              itemBuilder: (context, index) {
                return _buildListingCard(filteredListings[index]);
              },
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _applySorting(
      List<Map<String, dynamic>> listings) {
    switch (_sortBy) {
      case 'price_low':
        listings.sort((a, b) {
          final priceA = (a['price'] ?? 0).toDouble();
          final priceB = (b['price'] ?? 0).toDouble();
          return priceA.compareTo(priceB);
        });
        break;

      case 'price_high':
        listings.sort((a, b) {
          final priceA = (a['price'] ?? 0).toDouble();
          final priceB = (b['price'] ?? 0).toDouble();
          return priceB.compareTo(priceA);
        });
        break;

      case 'distance_near':
        if (_userLocation != null &&
            _userLocation!['latitude'] != null &&
            _userLocation!['longitude'] != null) {
          final userLat = _userLocation!['latitude'] as double;
          final userLon = _userLocation!['longitude'] as double;

          listings = _locationService.sortListingsByDistance(
            listings: listings,
            userLat: userLat,
            userLon: userLon,
          );
        }
        break;

      case 'distance_far':
        if (_userLocation != null &&
            _userLocation!['latitude'] != null &&
            _userLocation!['longitude'] != null) {
          final userLat = _userLocation!['latitude'] as double;
          final userLon = _userLocation!['longitude'] as double;

          listings = _locationService.sortListingsByDistance(
            listings: listings,
            userLat: userLat,
            userLon: userLon,
          );
          listings = listings.reversed.toList();
        }
        break;

      case 'none':
      default:
        break;
    }

    return listings;
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final imageUrls = listing['image_urls'] as List<dynamic>? ?? [];
    final hasImage = imageUrls.isNotEmpty;

    final showDistance =
        (_sortBy == 'distance_near' || _sortBy == 'distance_far') &&
            _userLocation != null &&
            listing['distance_text'] != null;

    return RepaintBoundary(
      child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingDetailPage(
              listing: listing,
              user: widget.user,
            ),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _line, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrls[0].toString(),
                          fit: BoxFit.cover,
                          memCacheWidth: 600,
                          fadeInDuration: const Duration(milliseconds: 160),
                          placeholder: (context, _) => const ColoredBox(
                            color: Color(0xFFF1EDF4),
                            child: Center(child: ImagePlaceholder()),
                          ),
                          errorWidget: (context, _, __) =>
                              const ImagePlaceholder(),
                        )
                      : const ImagePlaceholder(),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x33000000)],
                        ),
                      ),
                    ),
                  ),
                  if (showDistance)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _buildCardBadge(
                        Icons.location_on_outlined,
                        listing['distance_text'],
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatPrice(listing['price']),
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      listing['title'] ?? 'No title',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildMiniPill(listing['size'] ?? 'N/A'),
                        _buildMiniPill(listing['condition'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildCardBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _muted,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final numericPrice = price is num
        ? price.toDouble()
        : double.tryParse(price?.toString() ?? '') ?? 0.0;
    return 'PHP ${numericPrice.toStringAsFixed(2)}';
  }
}
