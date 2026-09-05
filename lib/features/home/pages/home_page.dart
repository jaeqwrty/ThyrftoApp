import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/features/home/widgets/home_widgets.dart';
import 'package:thryfto/features/home/pages/notification_page.dart';
import 'package:thryfto/shared/widgets/notification_bell.dart';
import 'package:thryfto/core/providers/home_providers.dart';
import 'package:thryfto/shared/widgets/skeleton_loaders.dart';

class HomePage extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onScrollToTop;

  const HomePage({super.key, required this.user, this.onScrollToTop});

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
              ],
            ),
          ),
        ),
      ],
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
              MaterialPageRoute(
                  builder: (context) => const NotificationsPage())),
        ),
        const SizedBox(width: 7),
      ],
    );
  }
}
