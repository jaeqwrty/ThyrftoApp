import 'package:cloud_firestore/cloud_firestore.dart';

class ListingStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Marks an active listing as sold outside the in-app reservation flow.
  /// Reserved listings must complete through their accepted transaction.
  Future<bool> markAsSold(String listingId) async {
    try {
      final listingRef = _firestore.collection('listings').doc(listingId);
      await _firestore.runTransaction((transaction) async {
        final listing = await transaction.get(listingRef);
        if (!listing.exists || listing.data()?['status'] != 'active') {
          throw StateError('Only an active listing can be marked sold directly');
        }
        transaction.update(listingRef, {
          'status': 'sold',
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
      return true;
    } catch (e) {
      print('Error marking listing as sold: $e');
      return false;
    }
  }
}
