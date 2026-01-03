// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thryfto/global/app_colors.dart';
import 'package:thryfto/homeWidgets/home_widgets.dart';
import 'package:thryfto/pages/notification_page.dart';
import 'package:thryfto/shared/notification_bell.dart';
import 'package:thryfto/providers/home_providers.dart';

class HomePage extends ConsumerWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
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
            slivers: [
              _buildAppBar(context),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final listing = listings[index];
                    return PostCard(
                      key: ValueKey(listing['id']),
                      listing: listing,
                      user: user,
                      db: ref.read(databaseServiceProvider),
                      onBlockedUser: () {
                        ref.read(sortedListingsProvider.notifier).refresh();
                      },
                    );
                  },
                  childCount: listings.length,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
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
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
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

  SliverAppBar _buildAppBar(BuildContext context) {
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
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
        ),
        const SizedBox(width: 7),
      ],
    );
  }
}