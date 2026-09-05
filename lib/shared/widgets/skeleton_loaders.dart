import 'package:flutter/material.dart';

/// Provides one animation ticker to all skeleton blocks beneath it.
/// This avoids creating an AnimationController for every placeholder rectangle.
class SkeletonShimmer extends StatefulWidget {
  final Widget child;

  const SkeletonShimmer({super.key, required this.child});

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1250),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SkeletonShimmerScope(
      animation: _controller,
      child: RepaintBoundary(child: widget.child),
    );
  }
}

class _SkeletonShimmerScope extends InheritedWidget {
  final Animation<double> animation;

  const _SkeletonShimmerScope({
    required this.animation,
    required super.child,
  });

  static Animation<double>? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SkeletonShimmerScope>()
        ?.animation;
  }

  @override
  bool updateShouldNotify(_SkeletonShimmerScope oldWidget) {
    return oldWidget.animation != animation;
  }
}

Widget _withSkeletonShimmer(BuildContext context, Widget child) {
  if (_SkeletonShimmerScope.maybeOf(context) != null) return child;
  return SkeletonShimmer(child: child);
}

/// Lightweight skeleton block driven by the nearest shared shimmer ticker.
class Skeleton extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  const Skeleton({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 8,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final animation = _SkeletonShimmerScope.maybeOf(context);
    if (animation == null) return _buildBlock(0.35);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => _buildBlock(animation.value),
    );
  }

  Widget _buildBlock(double progress) {
    final center = -2.0 + (progress * 4.0);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(center - 1, 0),
          end: Alignment(center + 1, 0),
          colors: const [
            Color(0xFFE5DFEC),
            Color(0xFFF6F3F8),
            Color(0xFFE5DFEC),
          ],
          stops: const [0.2, 0.5, 0.8],
        ),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
    );
  }
}

/// Skeleton for a single post card in the home feed
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5DFEC), width: 0.7),
          bottom: BorderSide(color: Color(0xFFE5DFEC), width: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + username + location details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Skeleton(
                  shape: BoxShape.circle,
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 120, height: 14, borderRadius: 4),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Skeleton(width: 70, height: 11, borderRadius: 3),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE5DFEC),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Skeleton(width: 40, height: 11, borderRadius: 3),
                        ],
                      ),
                    ],
                  ),
                ),
                const Skeleton(width: 24, height: 24, borderRadius: 6),
              ],
            ),
          ),
          // Large main image area
          const AspectRatio(
            aspectRatio: 4 / 3,
            child: Skeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          // Actions and text info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Likes and comments stats
                Row(
                  children: [
                    const Skeleton(width: 80, height: 13, borderRadius: 4),
                    const Spacer(),
                    const Skeleton(width: 100, height: 13, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 12),
                // Description lines
                const Skeleton(width: double.infinity, height: 13, borderRadius: 4),
                const SizedBox(height: 6),
                const Skeleton(width: 220, height: 13, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

/// Scrollable list of post card skeletons for home feed loading
class PostCardListSkeleton extends StatelessWidget {
  final int itemCount;
  const PostCardListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => const PostCardSkeleton(),
    ));
  }
}

/// Skeleton for a single listing card in the listings grids
class ListingCardSkeleton extends StatelessWidget {
  const ListingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DFEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          const Expanded(
            flex: 6,
            child: Skeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 15, // Matches the clipped border radius
            ),
          ),
          // Details area
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  const Skeleton(width: 60, height: 15, borderRadius: 4),
                  const SizedBox(height: 6),
                  // Title
                  const Skeleton(width: 110, height: 12, borderRadius: 4),
                  const Spacer(),
                  // Badges (Size and Condition)
                  Row(
                    children: [
                      const Skeleton(width: 40, height: 18, borderRadius: 6),
                      const SizedBox(width: 6),
                      const Skeleton(width: 55, height: 18, borderRadius: 6),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

/// Grid of listing card skeletons
class ListingGridSkeleton extends StatelessWidget {
  final int itemCount;
  const ListingGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ListingCardSkeleton(),
    ));
  }
}

/// Skeleton for a chat tile in conversation lists
class ChatTileSkeleton extends StatelessWidget {
  const ChatTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DFEC)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Avatar
            const Skeleton(
              shape: BoxShape.circle,
              width: 48,
              height: 48,
            ),
            const SizedBox(width: 12),
            // Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 110, height: 15, borderRadius: 4),
                  const SizedBox(height: 6),
                  const Skeleton(width: 180, height: 13, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Timestamp
            const Skeleton(width: 25, height: 12, borderRadius: 4),
          ],
        ),
      ),
    ));
  }
}

/// Scrollable list of chat tile skeletons
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;
  const ChatListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ChatTileSkeleton(),
    ));
  }
}

/// Skeleton for message bubble item in conversation page
class MessageBubbleSkeleton extends StatelessWidget {
  final bool isMe;
  const MessageBubbleSkeleton({super.key, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFE5DFEC).withOpacity(0.3) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: Border.all(color: const Color(0xFFE5DFEC), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Skeleton(
              width: isMe ? 140 : 180,
              height: 14,
              borderRadius: 4,
            ),
            const SizedBox(height: 4),
            if (!isMe)
              const Skeleton(
                width: 100,
                height: 14,
                borderRadius: 4,
              ),
          ],
        ),
      ),
    ));
  }
}

/// ListView of alternating message bubble skeletons
class MessageListSkeleton extends StatelessWidget {
  final int itemCount;
  const MessageListSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return MessageBubbleSkeleton(isMe: isMe);
      },
    ));
  }
}

/// Skeleton for profile metadata (avatar, stats, bio)
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DFEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              const Skeleton(
                shape: BoxShape.circle,
                width: 72,
                height: 72,
              ),
              const SizedBox(width: 16),
              // Stats counters
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (index) => const Column(
                      children: [
                        Skeleton(width: 30, height: 16, borderRadius: 4),
                        SizedBox(height: 4),
                        Skeleton(width: 50, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and username
          const Skeleton(width: 150, height: 18, borderRadius: 4),
          const SizedBox(height: 6),
          const Skeleton(width: 100, height: 13, borderRadius: 4),
          const SizedBox(height: 12),
          // Bio lines
          const Skeleton(width: double.infinity, height: 13, borderRadius: 4),
          const SizedBox(height: 6),
          const Skeleton(width: 200, height: 13, borderRadius: 4),
        ],
      ),
    ));
  }
}

/// Skeleton for full user profile page
class UserProfilePageSkeleton extends StatelessWidget {
  const UserProfilePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_rounded, color: Color(0xFF17131F)),
        title: const Skeleton(width: 100, height: 18, borderRadius: 4),
      ),
      body: SkeletonShimmer(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 6, 14, 10),
            child: ProfileHeaderSkeleton(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(
              children: [
                const Skeleton(width: 80, height: 18, borderRadius: 4),
                const Spacer(),
                const Skeleton(width: 60, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const Expanded(
            child: ListingGridSkeleton(itemCount: 4),
          ),
        ],
      )),
    );
  }
}

/// Skeleton for a notification row item
class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5DFEC)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar of action sender
          const Skeleton(
            shape: BoxShape.circle,
            width: 42,
            height: 42,
          ),
          const SizedBox(width: 12),
          // Notification description text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: 180, height: 14, borderRadius: 4),
                const SizedBox(height: 6),
                const Skeleton(width: 100, height: 11, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Visual thumbnail for the item/comment action reference
          const Skeleton(width: 40, height: 40, borderRadius: 8),
        ],
      ),
    ));
  }
}

/// Scrollable list of notification skeletons
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;
  const NotificationListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return _withSkeletonShimmer(context, ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: itemCount,
      itemBuilder: (context, index) => const NotificationTileSkeleton(),
    ));
  }
}
