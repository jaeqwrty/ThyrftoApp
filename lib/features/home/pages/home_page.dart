import 'package:flutter/material.dart';
import 'package:thryfto/core/utils/app_page_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/features/home/widgets/home_widgets.dart';
import 'package:thryfto/features/home/pages/notification_page.dart';
import 'package:thryfto/shared/widgets/notification_bell.dart';
import 'package:thryfto/core/providers/home_providers.dart';
import 'package:thryfto/shared/widgets/skeleton_loaders.dart';

class HomePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onScrollToTop;
  final ValueChanged<String?>? onExplore;

  const HomePage({
    super.key,
    required this.user,
    this.onScrollToTop,
    this.onExplore,
  });

  @override
  ConsumerState<HomePage> createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _page = Color(0xFFF6F3F8);
  static const Color _line = Color(0xFFE5DFEC);

  @override
  void initState() {
    super.initState();
    if (widget.onScrollToTop != null) {
      // Listen for scroll to top callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // This will be called from MainNavigation
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: _buildHomeFeed(context, ref),
      ),
    );
  }

  Widget _buildHomeFeed(BuildContext context, WidgetRef ref) {
    final sortedListingsAsync = ref.watch(sortedListingsProvider);

    return sortedListingsAsync.when(
      data: (listings) {
        if (listings.isEmpty) {
          return _buildEmptyState(context);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.read(sortedListingsProvider.notifier).refresh();
          },
          child: CustomScrollView(
            controller: _scrollController,
            cacheExtent: 700,
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildDiscoveryStrip()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final listing = listings[index];
                    return PostCard(
                      key: ValueKey(listing['id']),
                      listing: listing,
                      user: widget.user,
                      db: ref.read(databaseServiceProvider),
                      onBlockedUser: () {
                        ref.read(sortedListingsProvider.notifier).refresh();
                      },
                    );
                  },
                  childCount: listings.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: false,
                ),
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        return Center(child: Text('Error: $error'));
      },
      loading: () {
        return const PostCardListSkeleton();
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(child: _buildDiscoveryStrip()),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _line),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 32,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No listings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse categories while sellers add fresh finds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: widget.onExplore == null
                      ? null
                      : () => widget.onExplore!(null),
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('Browse items'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryStrip() {
    const categories = [
      ('Clothing', Icons.checkroom_outlined),
      ('Shoewear', Icons.hiking_outlined),
      ('Accessories', Icons.watch_outlined),
      ('Bags', Icons.shopping_bag_outlined),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: const Color(0xFFF6F3F8),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: widget.onExplore == null
                  ? null
                  : () => widget.onExplore!(null),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: _muted, size: 21),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search thrift finds',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: _muted, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ActionChip(
                  avatar: Icon(category.$2, size: 15, color: _ink),
                  label: Text(category.$1),
                  onPressed: widget.onExplore == null
                      ? null
                      : () => widget.onExplore!(category.$1),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _line),
                  labelStyle: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      shape: const Border(bottom: BorderSide(color: _line)),
      titleSpacing: 18,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thryfto',
            style: TextStyle(
              color: _ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: 1),
          Text(
            'Fresh finds near you',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      actions: [
        NotificationBell(
          onPressed: () => Navigator.push(
              context,
              AppPageRoute.fadeThrough(
                  builder: (context) => const NotificationsPage())),
        ),
        const SizedBox(width: 7),
      ],
    );
  }
}
