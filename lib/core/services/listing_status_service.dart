import 'package:cloud_firestore/cloud_firestore.dart';

class ListingStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates a listing's status to 'sold'
  Future<bool> markAsSold(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).update({
        'status': 'sold',
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error marking listing as sold: $e');
      return false;
    }
  }
}