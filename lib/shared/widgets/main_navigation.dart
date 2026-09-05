import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thryfto/features/home/pages/home_page.dart';
import 'package:thryfto/features/search/search_page.dart';
import 'package:thryfto/features/listings/pages/sell_page.dart';
import 'package:thryfto/features/chat/pages/chat_page.dart';
import 'package:thryfto/features/profile/pages/profile_page.dart';
import 'package:thryfto/core/constants/app_colors.dart';

class MainNavigation extends StatefulWidget {
  final Map<String, dynamic> user;

  const MainNavigation({super.key, required this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<SearchPageState> _searchPageKey = GlobalKey<SearchPageState>();
  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _line = Color(0xFFE5DFEC);

  // List of all 5 main pages
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        key: _homePageKey,
        user: widget.user,
        onExplore: _openSearch,
      ), // Index 0: Home
      SearchPage(key: _searchPageKey, user: widget.user), // Index 1: Search
      SellPage(user: widget.user), // Index 2: Sell
      ChatListPage(user: widget.user), // Index 3: Chats
      ProfilePage(user: widget.user), // Index 4: Profile
    ];
  }

  void _openSearch(String? category) {
    if (_selectedIndex != 1) {
      HapticFeedback.selectionClick();
      setState(() => _selectedIndex = 1);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchPageKey.currentState?.openFromMarketplace(category);
    });
  }

  void _onItemTapped(int index) {
    // If tapping Home while already on Home, scroll to top
    if (index == 0 && _selectedIndex == 0) {
      _homePageKey.currentState?.scrollToTop();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: List.generate(_pages.length, (index) {
          final isSelected = index == _selectedIndex;
          final horizontalOffset = index < _selectedIndex ? -0.025 : 0.025;

          return Positioned.fill(
            child: IgnorePointer(
              ignoring: !isSelected,
              child: ExcludeSemantics(
                excluding: !isSelected,
                child: TickerMode(
                  enabled: isSelected,
                  child: AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSlide(
                      offset: isSelected
                          ? Offset.zero
                          : Offset(horizontalOffset, 0),
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: _pages[index],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _line)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
          child: Row(
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _buildNavItem(
                  1, Icons.search_outlined, Icons.search_rounded, 'Search'),
              _buildNavItem(
                  2, Icons.add_box_outlined, Icons.add_box_rounded, 'Sell'),
              _buildNavItem(3, Icons.chat_bubble_outline_rounded,
                  Icons.chat_bubble_rounded, 'Chats'),
              _buildNavItem(
                  4, Icons.person_outline_rounded, Icons.person_rounded, 'Me'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final selected = _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 48,
          decoration: BoxDecoration(
            color: selected ? _ink : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Icon(
                  selected ? activeIcon : icon,
                  color: selected ? Colors.white : _muted,
                  size: 21,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : _muted,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
