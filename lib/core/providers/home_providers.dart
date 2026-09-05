import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/core/services/block_service.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/services/favorite_service.dart';

// Service providers
final databaseServiceProvider = Provider((ref) => DatabaseService());
final blockServiceProvider = Provider((ref) => BlockService());
final favoritesServiceProvider = Provider((ref) => FavoritesService());

// Followed sellers stream provider
final followedSellersProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final favoritesService = ref.watch(favoritesServiceProvider);
  return favoritesService.getFavoritedSellers();
});

// State notifier for home listings that prevents rebuilds on like changes
class HomeListingsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  HomeListingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    unawaited(_initialize());
  }

  final Ref _ref;
  StreamSubscription? _listingsSubscription;
  StreamSubscription? _followedSubscription;
  List<String> _followedIds = [];
  List<Map<String, dynamic>> _latestListings = [];
  List<String>? _previousListingVersions;

  Future<void> _initialize() async {
    await _listingsSubscription?.cancel();
    await _followedSubscription?.cancel();

    // Listen to followed sellers and immediately re-sort the current feed.
    _followedSubscription = _ref
        .read(favoritesServiceProvider)
        .getFavoritedSellers()
        .listen((followedIds) {
      _followedIds = followedIds;
      if (_latestListings.isNotEmpty) {
        _updateState(_latestListings);
      }
    });

    // Listen to active listings.
    final dbService = _ref.read(databaseServiceProvider);
    final blockService = _ref.read(blockServiceProvider);

    _listingsSubscription = dbService
        .getActiveListings()
        .asyncMap(blockService.filterBlockedListings)
        .listen((listings) {
      _latestListings = listings;

      // Rebuild when listing membership/order or persisted listing content changes.
      // Like/share/view counters intentionally do not touch updated_at, so those
      // high-frequency interactions continue to use their granular streams.
      final currentVersions = listings.map(_listingVersion).toList();
      if (_previousListingVersions == null ||
          !_listEquals(_previousListingVersions!, currentVersions)) {
        _previousListingVersions = currentVersions;
        _updateState(listings);
      }
    });
  }

  String _listingVersion(Map<String, dynamic> listing) {
    return '${listing['id']}|${listing['status']}|${listing['updated_at']}';
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _updateState(List<Map<String, dynamic>> listings) {
    final sortedListings = [...listings];
    sortedListings.sort((a, b) {
      bool aFollowed = _followedIds.contains(a['seller_id']);
      bool bFollowed = _followedIds.contains(b['seller_id']);

      if (aFollowed && !bFollowed) return -1;
      if (!aFollowed && bFollowed) return 1;

      Timestamp aTime = a['created_at'] ?? Timestamp.now();
      Timestamp bTime = b['created_at'] ?? Timestamp.now();
      return bTime.compareTo(aTime);
    });
    
    state = AsyncValue.data(sortedListings);
  }

  void refresh() {
    _previousListingVersions = null;
    _latestListings = [];
    state = const AsyncValue.loading();
    unawaited(_initialize());
  }

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    _followedSubscription?.cancel();
    super.dispose();
  }
}

// Use StateNotifierProvider instead of FutureProvider
final sortedListingsProvider = StateNotifierProvider.autoDispose<HomeListingsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return HomeListingsNotifier(ref);
});

// Keep the old providers for backward compatibility but mark as deprecated
@Deprecated('Use sortedListingsProvider directly')
final activeListingsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getActiveListings();
});

@Deprecated('Use sortedListingsProvider directly')
final filteredListingsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final blockService = ref.watch(blockServiceProvider);
  final activeListingsAsyncValue = ref.watch(activeListingsProvider);

  return activeListingsAsyncValue.when(
    data: (listings) => blockService.filterBlockedListings(listings),
    error: (error, stackTrace) => throw error,
    loading: () => [],
  );
});
