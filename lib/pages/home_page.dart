import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, String> user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _items = [
    {
      'username': 'vintage_vibes',
      'location': 'Brooklyn, NY',
      'image':
          'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500',
      'likes': 124,
      'price': 45,
      'title': 'Vintage Leather Jacket',
      'size': 'Size M',
      'condition': 'Excellent',
      'description':
          'vintage_vibes Found this gem at a local estate sale! ❤️ Genuine leather from the 80s, super soft and broken in perfectly.',
    },
    {
      'username': 'thrift_queen',
      'location': 'Austin, TX',
      'image':
          'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?w=500',
      'likes': 89,
      'price': 28,
      'title': 'Retro Denim Jacket',
      'size': 'Size S',
      'condition': 'Good',
      'description':
          'thrift_queen Classic 90s denim jacket. Perfect for layering! Minor wear on elbows adds to the character.',
    },
    {
      'username': 'secondhand_style',
      'location': 'Portland, OR',
      'image':
          'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=500',
      'likes': 203,
      'price': 35,
      'title': 'Wool Blend Coat',
      'size': 'Size L',
      'condition': 'Like New',
      'description':
          'secondhand_style Cozy wool blend coat, barely worn! Perfect condition and super warm for winter.',
    },
    {
      'username': 'eco_fashion',
      'location': 'Seattle, WA',
      'image':
          'https://images.unsplash.com/photo-1548126032-079877a0f19c?w=500',
      'likes': 156,
      'price': 52,
      'title': 'Designer Blazer',
      'size': 'Size M',
      'condition': 'Excellent',
      'description':
          'eco_fashion High-end designer piece at thrift store price! 🔥 Tailored fit, structured shoulders.',
    },
    {
      'username': 'retro_finds',
      'location': 'Chicago, IL',
      'image':
          'https://images.unsplash.com/photo-1578932750294-f5075e85f44a?w=500',
      'likes': 178,
      'price': 38,
      'title': 'Vintage Band Tee',
      'size': 'Size M',
      'condition': 'Good',
      'description':
          'retro_finds Original 80s band tee! Has that perfect worn-in feel. A true collector\'s item.',
    },
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thryfto',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B5CF6),
                      letterSpacing: 1.2,
                    ),
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.logout),
                  //   onPressed: () {
                  //     Navigator.pushReplacement(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const LoginScreen(),
                  //       ),
                  //     );
                  //   },
                  // ),
                ],
              ),
            ),
            // Scrollable feed
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(_items[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF8B5CF6),
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: 'Sell',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chats',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF8B5CF6),
                  child: Text(
                    item['username'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['username'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        item['location'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Item image
          Container(
            height: 400,
            width: double.infinity,
            color: Colors.grey[200],
            child: Image.network(
              item['image'],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.ios_share),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Likes count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              '${item['likes']} likes',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          // Price and title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Text(
                  '${item['price']} • ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                Expanded(
                  child: Text(
                    item['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Size and condition
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['size'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item['condition'],
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              item['description'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          // Message seller button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message feature coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.send, size: 18),
                label: const Text(
                  'Message Seller',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
