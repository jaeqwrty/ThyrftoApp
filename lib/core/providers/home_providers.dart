import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thryfto/core/services/database_service.dart';
import 'package:thryfto/core/services/block_service.dart';
import 'package:thryfto/core/services/favorite_service.dart';
import 'dart:async';

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
    _initialize();
  }

  final Ref _ref;
  StreamSubscription? _listingsSubscription;
  StreamSubscription? _followedSubscription;
  List<String> _followedIds = [];
  List<String>? _previousListingIds;

  void _initialize() async {
    // Listen to followed sellers
    _followedSubscription = _ref.read(favoritesServiceProvider).getFavoritedSellers().listen((followedIds) {
      _followedIds = followedIds;
      _processListings();
    });

    // Listen to active listings
    final dbService = _ref.read(databaseServiceProvider);
    final blockService = _ref.read(blockServiceProvider);
    
    _listingsSubscription = dbService.getActiveListings().asyncMap((listings) async {
      return await blockService.filterBlockedListings(listings);
    }).listen((listings) {
      // Check if the list structure changed (not just like counts)
      final currentIds = listings.map((l) => l['id'] as String).toList();
      
      if (_previousListingIds == null || !_listEquals(_previousListingIds!, currentIds)) {
        _previousListingIds = currentIds;
        _updateState(listings);
      }
      // If only internal data changed (like counts), don't update state
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _processListings() {
    // Trigger a re-process when followed sellers change
    if (_listingsSubscription != null) {
      // The next listing update will be processed
    }
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
    _previousListingIds = null;
    state = const AsyncValue.loading();
    _initialize();
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
