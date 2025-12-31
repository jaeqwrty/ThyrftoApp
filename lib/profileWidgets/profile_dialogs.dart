import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/services/rating_service.dart';
import 'package:thryfto/services/notification_service.dart';
import 'package:thryfto/services/database_service.dart';
import 'package:thryfto/profileWidgets/user_profileWidgets.dart';

/// Compact rating dialog for rating a seller - FIXED OVERFLOW ISSUES
class RatingDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String userId,
    required String sellerName,
    required Map<String, dynamic> currentUser,
    required RatingService ratingService,
    required NotificationService notificationService,
  }) async {
    final existingRating = await ratingService.getUserRating(userId);
    double rating = existingRating?['rating']?.toDouble() ?? 0.0;
    String review = existingRating?['review'] ?? '';

    final reviewController = TextEditingController(text: review);

    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      useSafeArea: true,
      builder: (context) => _RatingDialogContent(
        userId: userId,
        sellerName: sellerName,
        currentUser: currentUser,
        ratingService: ratingService,
        notificationService: notificationService,
        existingRating: existingRating,
        initialRating: rating,
        reviewController: reviewController,
      ),
    );
  }
}

class _RatingDialogContent extends StatefulWidget {
  final String userId;
  final String sellerName;
  final Map<String, dynamic> currentUser;
  final RatingService ratingService;
  final NotificationService notificationService;
  final Map<String, dynamic>? existingRating;
  final double initialRating;
  final TextEditingController reviewController;

  const _RatingDialogContent({
    required this.userId,
    required this.sellerName,
    required this.currentUser,
    required this.ratingService,
    required this.notificationService,
    required this.existingRating,
    required this.initialRating,
    required this.reviewController,
  });

  @override
  State<_RatingDialogContent> createState() => _RatingDialogContentState();
}

class _RatingDialogContentState extends State<_RatingDialogContent> {
  late double rating;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: keyboardHeight > 0 ? 8 : 16,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 380,
          maxHeight: screenHeight - keyboardHeight - 50,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            20,
            16,
            keyboardHeight > 0 ? 8 : 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existingRating == null
                    ? 'Rate ${widget.sellerName}'
                    : 'Update Rating',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 26,
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () => setState(() => rating = (index + 1).toDouble()),
                    );
                  }),
                ),
              ),

              if (rating > 0) ...[
                const SizedBox(height: 4),
                Text(
                  _getRatingText(rating),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 12),

              TextField(
                controller: widget.reviewController,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: 'Review (optional)',
                  labelStyle: const TextStyle(fontSize: 13),
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  counterText: '',
                ),
                style: const TextStyle(fontSize: 14),
                minLines: 1,
                maxLines: 3,
                maxLength: 200,
                scrollPhysics: const ClampingScrollPhysics(),
              ),

              const SizedBox(height: 12),

              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (widget.existingRating != null)
                    TextButton.icon(
                      onPressed: isSubmitting ? null : _handleDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 34),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: (rating > 0 && !isSubmitting) ? _handleSubmit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: const Size(80, 34),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating'),
        content: const Text('Are you sure you want to delete your rating?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => isSubmitting = true);
      final deleted = await widget.ratingService.deleteRating(widget.userId);
      if (mounted) Navigator.pop(context, deleted);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => isSubmitting = true);

    final success = await widget.ratingService.rateSeller(
      sellerId: widget.userId,
      rating: rating,
      review: widget.reviewController.text.trim().isEmpty
          ? null
          : widget.reviewController.text.trim(),
    );

    if (success) {
      final currentUserName = widget.currentUser['fullName'] ??
          widget.currentUser['full_name'] ??
          'Someone';
      await widget.notificationService.createNotification(
        recipientId: widget.userId,
        type: 'rating',
        title: 'New Rating',
        body: '$currentUserName rated you ${rating.toStringAsFixed(1)} stars',
        relatedUserId: FirebaseAuth.instance.currentUser?.uid,
        additionalData: {
          'rating': rating,
          'review': widget.reviewController.text.trim(),
        },
      );
    }

    if (mounted) Navigator.pop(context, success);
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    widget.reviewController.dispose();
    super.dispose();
  }
}

/// Ratings bottom sheet - REALTIME PROFILE UPDATES
class RatingsBottomSheet {
  static void show({
    required BuildContext context,
    required String userId,
    required RatingService ratingService,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: ratingService.getSellerRatingStatsStream(userId),
                  initialData: const {
                    'average_rating': 0.0,
                    'ratings_count': 0,
                  },
                  builder: (context, statsSnapshot) {
                    final stats = statsSnapshot.data ?? {
                      'average_rating': 0.0,
                      'ratings_count': 0,
                    };
                    final avgRating = stats['average_rating'] as double;
                    final count = stats['ratings_count'] as int;

                    return Column(
                      children: [
                        const Text(
                          'Ratings & Reviews',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ' ($count ${count == 1 ? 'rating' : 'ratings'})',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ratingService.getSellerRatings(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final ratings = snapshot.data ?? [];

                    if (ratings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_outline, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No ratings yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: ratings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final rating = ratings[index];
                        final reviewerId = rating['reviewer_id'] as String?;
                        final timestamp = rating['created_at']?.toDate();
                        final reviewText = rating['review'] as String?;
                        final hasReview = reviewText != null && reviewText.isNotEmpty;

                        // Use realtime profile data if reviewer_id exists
                        return _RatingCardWithRealtimeProfile(
                          rating: rating,
                          reviewerId: reviewerId,
                          timestamp: timestamp,
                          reviewText: reviewText,
                          hasReview: hasReview,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that displays rating card with realtime profile updates
class _RatingCardWithRealtimeProfile extends StatelessWidget {
  final Map<String, dynamic> rating;
  final String? reviewerId;
  final DateTime? timestamp;
  final String? reviewText;
  final bool hasReview;

  const _RatingCardWithRealtimeProfile({
    required this.rating,
    required this.reviewerId,
    required this.timestamp,
    required this.reviewText,
    required this.hasReview,
  });

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    // If reviewer_id exists, stream their profile for realtime updates
    if (reviewerId != null && reviewerId!.isNotEmpty) {
      return StreamBuilder<Map<String, dynamic>?>(
        stream: db.getUserProfileStream(reviewerId!),
        builder: (context, profileSnapshot) {
          // Use realtime data if available, fallback to cached data
          final profileImageUrl = profileSnapshot.data?['profileImageUrl'] as String? ??
              rating['reviewer_image'] as String?;
          final reviewerName = profileSnapshot.data?['fullName'] as String? ??
              profileSnapshot.data?['full_name'] as String? ??
              rating['reviewer_name'] as String? ??
              'Anonymous';

          return _buildRatingCard(
            reviewerName: reviewerName,
            profileImageUrl: profileImageUrl,
          );
        },
      );
    }

    // Fallback to static data if no reviewer_id
    return _buildRatingCard(
      reviewerName: rating['reviewer_name'] as String? ?? 'Anonymous',
      profileImageUrl: rating['reviewer_image'] as String?,
    );
  }

  Widget _buildRatingCard({
    required String reviewerName,
    required String? profileImageUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF8B5CF6),
                backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: (profileImageUrl == null || profileImageUrl.isEmpty)
                    ? Text(
                        reviewerName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < (rating['rating'] ?? 0).toInt()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (timestamp != null)
                Text(
                  formatDate(timestamp!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          if (hasReview) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(reviewText!),
            ),
          ],
        ],
      ),
    );
  }
}