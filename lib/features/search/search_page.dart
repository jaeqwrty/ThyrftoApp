import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/shared/widgets/empty_state.dart';
import 'package:thryfto/shared/widgets/error.dart';
import 'package:thryfto/shared/widgets/image_placeholder.dart';
import 'package:thryfto/shared/widgets/tag.dart';
import 'package:thryfto/features/listings/pages/listing_detail_page.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/services/block_service.dart';
import 'package:thryfto/core/constants/app_colors.dart';

class SearchPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const SearchPage({super.key, required this.user});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

Stream<Map<String, dynamic>?>? _userLocationStream;

class _SearchPageState extends State<SearchPage> {
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
        _userLocationStream =
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
        _userLocationStream?.listen((location) {
          if (mounted) {
            setState(() {
              _userLocation = location;
              // State update triggers rebuild, which recalculates distances!
            });
          }
        });
      }
    } catch (e) {
      print('Error setting up location stream: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Filter
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = category);
                            },
                            backgroundColor: Colors.white,
                            selectedColor:
                                const Color(0xFF8B5CF6).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF8B5CF6)
                                    : Colors.grey[300]!,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sort Options
                  Row(
                    children: [
                      Icon(Icons.sort, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Sort by:',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildSortChip('Relevance', 'none'),
                              _buildPriceSortChip(),
                              if (_userLocation != null)
                                _buildDistanceSortChip(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSortChip() {
    final isSelected = _sortBy == 'price_low' || _sortBy == 'price_high';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
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
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[700],
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
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF8B5CF6).withOpacity(0.15),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildDistanceSortChip() {
    final isSelected = _sortBy == 'distance_near' || _sortBy == 'distance_far';
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
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
              color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[700],
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
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF8B5CF6).withOpacity(0.15),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _sortBy = value);
        },
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF8B5CF6).withOpacity(0.15),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[300]!,
          ),
        ),
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
          return const Center(child: CircularProgressIndicator());
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
              return const Center(child: CircularProgressIndicator());
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
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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

    return GestureDetector(
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: hasImage
                        ? Image.network(
                            imageUrls[0],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const ImagePlaceholder(),
                          )
                        : const ImagePlaceholder(),
                  ),
                  if (showDistance)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              listing['distance_text'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₱${listing['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing['title'] ?? 'No title',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TagBadge.size(listing['size'] ?? 'N/A'),
                      const SizedBox(width: 6),
                      Flexible(
                        child:
                            TagBadge.condition(listing['condition'] ?? 'N/A'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
