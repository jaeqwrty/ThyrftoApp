import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/services/chat_service.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/services/listing_status_service.dart';
import 'package:thryfto/core/services/location_service.dart';
import 'package:thryfto/core/utils/common_dialogs.dart';
import 'package:thryfto/core/utils/snackbar_utils.dart';
import 'package:thryfto/features/chat/pages/conversation_page.dart';
import 'package:thryfto/features/listings/pages/edit_listing_page.dart';
import 'package:thryfto/features/profile/pages/profile_page.dart';
import 'package:thryfto/features/profile/pages/user_profile_page.dart';
import 'package:thryfto/shared/widgets/share_modal.dart';

class ListingDetailPage extends StatefulWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic> user;
  final String? heroTag;

  const ListingDetailPage({
    super.key,
    required this.listing,
    required this.user,
    this.heroTag,
  });

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  static const Color _ink = Color(0xFF17131F);
  static const Color _mutedInk = Color(0xFF625A70);
  static const Color _pageTint = Color(0xFFF6F3F8);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _wine = Color(0xFF5B2A6F);
  static const Color _gilt = Color(0xFFA8752A);

  final DatabaseService _db = DatabaseService();
  final ChatService _chatService = ChatService();
  final ListingStatusService _statusService = ListingStatusService();

  int _currentImageIndex = 0;
  bool _isLiked = false;
  bool _isBookmarked = false;
  int _likeCount = 0;
  bool _isSoldProcessing = false;
  bool _isOpeningChat = false;

  @override
  void initState() {
    super.initState();
    _loadInteractionStatus();
  }

  Future<void> _loadInteractionStatus() async {
    final listingId = widget.listing['id'];
    if (listingId == null) return;

    try {
      final liked = await _db.isListingLiked(listingId);
      final bookmarked = await _db.isListingBookmarked(listingId);
      if (!mounted) return;

      setState(() {
        _isLiked = liked;
        _isBookmarked = bookmarked;
        _likeCount = widget.listing['likes'] ?? 0;
      });
    } catch (_) {
      // The live streams still keep the page usable if this eager load fails.
    }
  }

  Future<void> _handleMarkAsSold() async {
    final confirmed = await CommonDialogs.showConfirmationDialog(
      context,
      title: 'Mark as Sold?',
      message:
          'This will hide the item from search results but keep it on your profile.',
      confirmText: 'Confirm',
    );

    if (confirmed != true) return;

    setState(() => _isSoldProcessing = true);
    final success = await _statusService.markAsSold(widget.listing['id']);

    if (!mounted) return;
    setState(() => _isSoldProcessing = false);

    if (success) {
      SnackbarUtils.showSuccess(context, 'Listing marked as sold.');
    } else {
      SnackbarUtils.showError(
        context,
        'We could not update the listing status. Please try again.',
        actionLabel: 'Try again',
        onAction: _handleMarkAsSold,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = (widget.listing['image_urls'] as List<dynamic>?) ?? [];
    final hasImages = imageUrls.isNotEmpty;
    final isOwnListing = widget.listing['seller_id'] == _db.currentUserId;

    return Scaffold(
      backgroundColor: _pageTint,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            elevation: 0,
            backgroundColor: _ink,
            surfaceTintColor: _ink,
            leading: _buildRoundIconButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              _buildRoundIconButton(
                icon: Icons.share_outlined,
                onPressed: _openShareSheet,
              ),
              StreamBuilder<bool>(
                stream:
                    _db.isListingBookmarkedStream(widget.listing['id'] ?? ''),
                initialData: _isBookmarked,
                builder: (context, snapshot) {
                  final isBookmarked = snapshot.data ?? _isBookmarked;
                  return _buildRoundIconButton(
                    icon: isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked ? AppColors.primary : Colors.black87,
                    onPressed: () => _toggleBookmark(isBookmarked),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageGallery(imageUrls, hasImages),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildListingSummary(),
                _buildDescriptionSection(),
                if (isOwnListing)
                  _buildOwnerStatusSection()
                else
                  _buildSellerSection(),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          isOwnListing ? _buildOwnerBottomBar() : _buildBuyerBottomBar(),
    );
  }

  Widget _buildImageGallery(List<dynamic> imageUrls, bool hasImages) {
    if (!hasImages) return _buildImagePlaceholder();

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: imageUrls.length,
          onPageChanged: (index) => setState(() => _currentImageIndex = index),
          itemBuilder: (context, index) {
            Widget image = InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: imageUrls[index].toString(),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                memCacheWidth: 1600,
                fadeInDuration: const Duration(milliseconds: 180),
                placeholder: (context, _) => _buildImagePlaceholder(),
                errorWidget: (context, _, __) => _buildImagePlaceholder(),
              ),
            );

            if (index == 0 && widget.heroTag != null) {
              image = Hero(tag: widget.heroTag!, child: image);
            }

            return image;
          },
        ),
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x22000000),
                  Color(0xAA000000),
                ],
                stops: [0, 0.48, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Text(
                  'CURATED THRIFT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.listing['status'] == 'sold')
          Positioned(
            left: 16,
            bottom: 58,
            child: _buildOverlayPill('SOLD', Icons.check_circle),
          ),
        if (imageUrls.length > 1)
          Positioned(
            right: 16,
            bottom: 16,
            child: _buildOverlayPill(
              '${_currentImageIndex + 1}/${imageUrls.length}',
              Icons.photo_library_outlined,
            ),
          ),
      ],
    );
  }

  Widget _buildListingSummary() {
    return _buildFlatSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THRYFTO FIND',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: _gilt,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _formatPrice(widget.listing['price']),
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    color: _wine,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _buildLikeButton(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.listing['title'] ?? 'No title',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          _buildAccentRule(),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailPill(
                  Icons.straighten, widget.listing['size'] ?? 'N/A'),
              _buildDetailPill(Icons.verified_outlined,
                  widget.listing['condition'] ?? 'N/A'),
              _buildDetailPill(Icons.category_outlined,
                  widget.listing['category'] ?? 'Other'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _buildFlatSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Description'),
          const SizedBox(height: 14),
          Text(
            widget.listing['description'] ?? 'No description available.',
            style: const TextStyle(
              fontSize: 15.5,
              color: _mutedInk,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerStatusSection() {
    return _buildFlatSection(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _db.getListingStream(widget.listing['id'] ?? ''),
        builder: (context, snapshot) {
          final listingData = snapshot.data ?? widget.listing;
          final isSold = listingData['status'] == 'sold';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Listing Status'),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isSold ? Icons.check_circle : Icons.sell_outlined,
                    color: isSold ? _mutedInk : _wine,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSold
                          ? 'This listing is marked as sold.'
                          : 'This listing is active and visible to shoppers.',
                      style: const TextStyle(
                        color: _mutedInk,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isSold) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSoldProcessing ? null : _handleMarkAsSold,
                    icon: _isSoldProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Mark as Sold'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: _wine),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSellerSection() {
    return _buildFlatSection(
      child: StreamBuilder<Map<String, dynamic>?>(
        stream: _db.getUserProfileStream(widget.listing['seller_id']),
        builder: (context, sellerSnapshot) {
          if (sellerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final seller = sellerSnapshot.data;
          final sellerName = seller?['fullName'] ??
              seller?['full_name'] ??
              seller?['username'] ??
              widget.listing['seller_name'] ??
              'Unknown Seller';
          final profileImageUrl = seller?['profileImageUrl'] as String?;
          final location = _sellerLocation(seller);
          final hasLocation = location != 'Location not set';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Seller'),
              const SizedBox(height: 14),
              InkWell(
                onTap: _openSellerProfile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _wine,
                        backgroundImage: (profileImageUrl != null &&
                                profileImageUrl.isNotEmpty)
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child:
                            (profileImageUrl == null || profileImageUrl.isEmpty)
                                ? Text(
                                    sellerName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sellerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: hasLocation
                                      ? AppColors.primary
                                      : _mutedInk,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: hasLocation
                                          ? _mutedInk
                                          : const Color(0xFF9B92A8),
                                      fontStyle: hasLocation
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: _gilt),
                    ],
                  ),
                ),
              ),
              _buildDistanceBadge(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLikeButton() {
    return StreamBuilder<bool>(
      stream: _db.isListingLikedStream(widget.listing['id'] ?? ''),
      initialData: _isLiked,
      builder: (context, likeSnapshot) {
        final isLiked = likeSnapshot.data ?? _isLiked;

        return StreamBuilder<Map<String, dynamic>?>(
          stream: _db.getListingStream(widget.listing['id'] ?? ''),
          builder: (context, listingSnapshot) {
            final currentLikes = listingSnapshot.data?['likes'] ?? _likeCount;
            return OutlinedButton.icon(
              onPressed: () async {
                final listingId = widget.listing['id'];
                if (listingId != null) {
                  await _db.toggleLikeWithNotification(listingId);
                }
              },
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: isLiked ? Colors.red : _mutedInk,
              ),
              label: Text('$currentLikes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                backgroundColor: const Color(0xFFFBFAFC),
                side: const BorderSide(color: _line),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBuyerBottomBar() {
    return _buildBottomShell(
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: _isOpeningChat ? null : _openChat,
          style: ElevatedButton.styleFrom(
            backgroundColor: _ink,
            disabledBackgroundColor: _ink.withValues(alpha: 0.62),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _isOpeningChat
                ? const Row(
                    key: ValueKey('opening-chat'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Opening chat…',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    key: ValueKey('message-seller'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Message Seller',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerBottomBar() {
    return _buildBottomShell(
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  AppPageRoute.fadeThrough(
                    builder: (context) => EditListingPage(
                      listing: widget.listing,
                      user: widget.user,
                    ),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _wine,
                side: const BorderSide(color: _wine),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handleDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton(
        onPressed: onPressed,
        icon: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }

  Widget _buildOverlayPill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }

  Widget _buildFlatSection({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFCFAFD)],
        ),
        border: Border(
          top: BorderSide(color: _line, width: 0.7),
          bottom: BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _gilt,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _buildAccentRule() {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x00A8752A), _gilt, Color(0x005B2A6F)],
        ),
      ),
    );
  }

  Widget _buildDetailPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _gilt),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              color: _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _db.getUserProfileStream(_db.currentUserId ?? ''),
      builder: (context, currentUserSnapshot) {
        final currentUser = currentUserSnapshot.data;
        double? currentUserLat;
        double? currentUserLon;

        if (currentUser != null) {
          if (currentUser['latitude'] != null &&
              currentUser['longitude'] != null) {
            currentUserLat = (currentUser['latitude'] as num).toDouble();
            currentUserLon = (currentUser['longitude'] as num).toDouble();
          } else if (currentUser['location'] != null) {
            final loc = currentUser['location'] as Map<String, dynamic>;
            currentUserLat = (loc['latitude'] as num?)?.toDouble();
            currentUserLon = (loc['longitude'] as num?)?.toDouble();
          }
        }

        final listingLocation =
            widget.listing['location'] as Map<String, dynamic>?;

        if (currentUserLat == null ||
            currentUserLon == null ||
            listingLocation == null ||
            listingLocation['latitude'] == null ||
            listingLocation['longitude'] == null) {
          return const SizedBox.shrink();
        }

        final distance = LocationService().calculateDistance(
          currentUserLat,
          currentUserLon,
          (listingLocation['latitude'] as num).toDouble(),
          (listingLocation['longitude'] as num).toDouble(),
        );

        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: _buildDetailPill(
            Icons.near_me_outlined,
            LocationService().formatDistance(distance),
          ),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFE9E2ED),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 76, color: _mutedInk),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final numericPrice = price is num
        ? price.toDouble()
        : double.tryParse(price?.toString() ?? '') ?? 0.0;
    return 'PHP ${numericPrice.toStringAsFixed(2)}';
  }

  String _sellerLocation(Map<String, dynamic>? seller) {
    if (seller == null) return 'Location not set';

    if (seller['address'] != null && seller['address'].toString().isNotEmpty) {
      return seller['address'].toString();
    }

    if (seller['cityState'] != null &&
        seller['cityState'].toString().isNotEmpty) {
      return seller['cityState'].toString();
    }

    if (seller['location'] is Map<String, dynamic>) {
      final location = seller['location'] as Map<String, dynamic>;
      if (location['address'] != null &&
          location['address'].toString().isNotEmpty) {
        return location['address'].toString();
      }
    }

    return 'Location not set';
  }

  void _openShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareModal(listing: widget.listing),
    );
  }

  Future<void> _toggleBookmark(bool isBookmarked) async {
    final listingId = widget.listing['id'];
    if (listingId == null) return;

    try {
      await _db.toggleBookmark(listingId);
      if (!mounted) return;

      setState(() => _isBookmarked = !isBookmarked);
      SnackbarUtils.showBookmark(context, _isBookmarked);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to bookmark: $e');
      }
    }
  }

  void _openSellerProfile() {
    final sellerId = widget.listing['seller_id'];
    if (sellerId == null) return;

    if (sellerId == _db.currentUserId) {
      Navigator.push(
        context,
        AppPageRoute.fadeThrough(builder: (context) => ProfilePage(user: widget.user)),
      );
      return;
    }

    Navigator.push(
      context,
      AppPageRoute.fadeThrough(
        builder: (context) => UserProfilePage(
          userId: sellerId,
          currentUser: widget.user,
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    if (!mounted || _isOpeningChat) return;
    setState(() => _isOpeningChat = true);

    try {
      final chatId =
          await _chatService.getOrCreateChat(widget.listing['seller_id']);

      if (!mounted) return;
      if (chatId != null) {
        setState(() => _isOpeningChat = false);
        Navigator.push(
          context,
          AppPageRoute.fadeThrough(
            builder: (context) => ConversationPage(
              chatId: chatId,
              otherUserId: widget.listing['seller_id'],
              otherUserName: widget.listing['seller_name'] ?? 'Seller',
              currentUser: widget.user,
            ),
          ),
        );
      } else {
        setState(() => _isOpeningChat = false);
        SnackbarUtils.showError(
            context, 'Failed to open chat. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isOpeningChat = false);
      SnackbarUtils.showError(
          context, 'Failed to open chat. Please try again.');
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await CommonDialogs.showDeleteConfirmationDialog(
      context,
      title: 'Delete Listing',
      message:
          'Are you sure you want to delete this listing? This action cannot be undone.',
      icon: Icons.delete_outline,
    );

    if (confirmed != true) return;

    final listingId = widget.listing['id'];
    if (listingId == null) return;

    final success = await _db.deleteListing(listingId);
    if (!mounted) return;

    if (success) {
      SnackbarUtils.showSuccess(context, 'Listing deleted successfully');
      Navigator.pop(context);
    } else {
      SnackbarUtils.showError(context, 'Failed to delete listing');
    }
  }
}
