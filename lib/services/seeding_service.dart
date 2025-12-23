import 'package:cloud_firestore/cloud_firestore.dart';

class SeedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDatabase(String currentUserId) async {
    final batch = _firestore.batch();

    // 1. Create some dummy users (Sellers)
    final sellers = [
      {
        'id': 'seller_1',
        'uid': 'seller_1',
        'username': 'vintage_vibe',
        'fullName': 'Vintage Vibe',
        'email': 'vintage@example.com',
        'cityState': 'Makati, Metro Manila',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'seller_2',
        'uid': 'seller_2',
        'username': 'thrifty_finds',
        'fullName': 'Thrifty Finds',
        'email': 'thrifty@example.com',
        'cityState': 'Quezon City, Metro Manila',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'seller_3',
        'uid': 'seller_3',
        'username': 'retro_corner',
        'fullName': 'Retro Corner',
        'email': 'retro@example.com',
        'cityState': 'Cebu City, Cebu',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var seller in sellers) {
      final docRef = _firestore.collection('users').doc(seller['id'] as String);
      batch.set(docRef, seller);
    }

    // 2. Create sample listings
    // We'll use reliable image placeholders
    final listings = [
      {
        'seller_id': 'seller_1',
        'seller_name': 'Vintage Vibe',
        'seller_location': 'Makati, Metro Manila',
        'title': 'Vintage Denim Jacket',
        'description': 'Classic 90s denim jacket in great condition. Slightly oversized fit.',
        'price': 850.00,
        'size': 'L',
        'condition': 'Good',
        'category': 'Clothing',
        'image_urls': [
          'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=500&auto=format&fit=crop&q=60',
          'https://images.unsplash.com/photo-1611312449408-fcece27cdbb7?w=500&auto=format&fit=crop&q=60',
        ],
        'status': 'active',
        'likes': 12,
        'views': 45,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'seller_id': 'seller_1',
        'seller_name': 'Vintage Vibe',
        'seller_location': 'Makati, Metro Manila',
        'title': 'Dr. Martens 1460 Boots',
        'description': 'Barely used Dr. Martens boots. Black leather, size 8 UK.',
        'price': 4500.00,
        'size': '42',
        'condition': 'Like New',
        'category': 'Shoes',
        'image_urls': [
          'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=500&auto=format&fit=crop&q=60',
        ],
        'status': 'active',
        'likes': 28,
        'views': 120,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'seller_id': 'seller_2',
        'seller_name': 'Thrifty Finds',
        'seller_location': 'Quezon City, Metro Manila',
        'title': 'Retro Film Camera',
        'description': 'Working condition Canon AE-1 via thrift find. Lens not included.',
        'price': 3200.00,
        'size': 'One Size',
        'condition': 'Good',
        'category': 'Electronics',
        'image_urls': [
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=500&auto=format&fit=crop&q=60',
        ],
        'status': 'active',
        'likes': 5,
        'views': 30,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'seller_id': 'seller_2',
        'seller_name': 'Thrifty Finds',
        'seller_location': 'Quezon City, Metro Manila',
        'title': 'Floral Summer Dress',
        'description': 'Light and airy summer dress, perfect for the beach.',
        'price': 350.00,
        'size': 'S',
        'condition': 'New',
        'category': 'Clothing',
        'image_urls': [
          'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=500&auto=format&fit=crop&q=60',
        ],
        'status': 'active',
        'likes': 42,
        'views': 150,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'seller_id': 'seller_3',
        'seller_name': 'Retro Corner',
        'seller_location': 'Cebu City, Cebu',
        'title': 'Nike Air Max 97',
        'description': 'Silver bullet colorway. Some signs of wear on the sole.',
        'price': 2800.00,
        'size': '44',
        'condition': 'Fair',
        'category': 'Shoes',
        'image_urls': [
          'https://images.unsplash.com/photo-1514989940723-e8e51635b782?w=500&auto=format&fit=crop&q=60',
        ],
        'status': 'active',
        'likes': 15,
        'views': 80,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      {
        'seller_id': currentUserId, // One for the current user to test "My Listings"
        'seller_name': 'You',
        'seller_location': 'Your Location',
        'title': 'My Old Guitar',
        'description': 'Acoustic guitar I learned to play on. Needs new strings.',
        'price': 1500.00,
        'size': 'N/A',
        'condition': 'Fair',
        'category': 'Other',
        'image_urls': [
          'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=500&auto=format&fit=crop&q=60',
        ],
        'status': 'active',
        'likes': 2,
        'views': 10,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }
    ];

    for (var listing in listings) {
      final docRef = _firestore.collection('listings').doc();
      batch.set(docRef, listing);
    }

    await batch.commit();
  }

  Future<void> clearAllData() async {
    // 1. Delete all listings
    final listings = await _firestore.collection('listings').get();
    final batch = _firestore.batch();
    for (var doc in listings.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete all users except for the "seller_" prefixed ones 
    // and potentially those that shouldn't be deleted.
    // For simplicity in dev, we'll delete users created by seed
    final seedUsers = ['seller_1', 'seller_2', 'seller_3'];
    for (var userId in seedUsers) {
      batch.delete(_firestore.collection('users').doc(userId));
    }

    await batch.commit();
  }
}
