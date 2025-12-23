import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.search,
                label: 'Search',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.add_circle,
                label: 'Sell',
                index: 2,
                isSpecial: true,
              ),
              _buildNavItem(
                icon: Icons.favorite,
                label: 'Favorites',
                index: 3,
              ),
              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    bool isSpecial = false,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSpecial
              ? const Color(0xFF8B5CF6)
              : (isSelected
                  ? const Color(0xFF8B5CF6).withOpacity(0.1)
                  : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSpecial ? 28 : 24,
              color: isSpecial
                  ? Colors.white
                  : (isSelected ? const Color(0xFF8B5CF6) : Colors.grey),
            ),
            if (!isSpecial) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

