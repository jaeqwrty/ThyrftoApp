import 'package:flutter/material.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/services/location_service.dart';
import 'package:thryfto/pages/listing_detail_page.dart';
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
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _db.getUserProfileStream(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found'));
          }

          final userData = snapshot.data!;
          final profileImageUrl = userData['profileImageUrl'] as String?;
          final fullName = userData['fullName'] ?? userData['full_name'] ?? 'User';
          final username = userData['username'] ?? 'unknown';
          final bio = userData['bio'] as String?;
          final displayBio = (bio == null || bio.trim().isEmpty) ? 'No bio' : bio;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF8B5CF6),
                          backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: (profileImageUrl == null || profileImageUrl.isEmpty)
                              ? Text(
                                  fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@$username',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              FutureBuilder<Map<String, dynamic>?>(
                                future: _locationService.getUserLocation(widget.userId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(height: 20);
                                  }
                                  String locationDisplay = 'Location not set';
                                  IconData locationIcon = Icons.location_off;
                                  Color locationColor = Colors.grey[500]!;

                                  if (snapshot.hasData && snapshot.data != null) {
                                    final address = snapshot.data!['address'] as String?;
                                    if (address != null && address.isNotEmpty && !address.startsWith('Lat:')) {
                                      locationDisplay = address;
                                      locationIcon = Icons.location_on;
                                      locationColor = const Color(0xFF8B5CF6);
                                    }
                                  }
                                  return Row(
                                    children: [
                                      Icon(locationIcon, size: 16, color: locationColor),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          locationDisplay,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: locationColor,
                                            fontWeight: locationIcon == Icons.location_on ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 2. Bio (Above button, start-aligned)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        displayBio,
                        style: TextStyle(
                          fontSize: 15,
                          color: (bio == null || bio.trim().isEmpty) ? Colors.grey[500] : Colors.black87,
                          fontStyle: (bio == null || bio.trim().isEmpty) ? FontStyle.italic : FontStyle.normal,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    // 3. Message Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final chatId = await _db.getOrCreateChat(widget.userId);
                          if (chatId != null && mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConversationPage(
                                  chatId: chatId,
                                  otherUserId: widget.userId,
                                  otherUserName: fullName,
                                  currentUser: widget.currentUser,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.message, size: 20),
                        label: const Text('Message Seller', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F7)),
              // 4. Listings Header with fixed pluralization
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _db.getUserListings(widget.userId),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.length ?? 0;
                        // Pluralization logic
                        final label = count == 1 ? 'item' : 'items';
                        return Text(
                          '$count $label',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // 5. Listings Grid
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _db.getUserListings(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                    final listings = snapshot.data ?? [];
                    if (listings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No listings yet', style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          ],
                        ),
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
                      itemCount: listings.length,
                      itemBuilder: (context, index) => _buildListingCard(listings[index]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ... (Keep the existing _buildListingCard and _buildImagePlaceholder helper methods)
  Widget _buildListingCard(Map<String, dynamic> listing) {
    final imageUrls = listing['image_urls'] as List<dynamic>? ?? [];
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ListingDetailPage(listing: listing, user: widget.currentUser))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrls.isNotEmpty
                    ? Image.network(imageUrls[0], width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildImagePlaceholder())
                    : _buildImagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('₱${listing['price']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                  const SizedBox(height: 4),
                  Text(listing['title'] ?? 'No title', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(listing['size'] ?? 'N/A', Colors.purple.shade50, const Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      _buildBadge(listing['condition'] ?? 'N/A', Colors.green.shade50, Colors.green.shade700),
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

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(color: Colors.grey[200], child: Center(child: Icon(Icons.image, size: 40, color: Colors.grey[400])));
  }
}