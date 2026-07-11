import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/features/profile/pages/profile_setup_page.dart';
import 'package:thryfto/features/auth/widgets/auth_widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _surface = Color(0xFFFBFAFC);

  final List<Map<String, String>> _pages = [
    {
      'title': 'Discover Unique Items',
      'description': 'Find one-of-a-kind thrift treasures from sellers near you.',
      'icon': 'search',
    },
    {
      'title': 'Sell with Ease',
      'description': 'Declutter your closet and make money by selling items you no longer need.',
      'icon': 'camera',
    },
    {
      'title': 'Connect with Community',
      'description': 'Chat with buyers and sellers and join a growing community of thryfters.',
      'icon': 'chat',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileSetupPage()),
                      );
                    },
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPageContent(_pages[index]);
                  },
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(Map<String, String> page) {
    IconData iconData;
    switch (page['icon']) {
      case 'search':
        iconData = Icons.search_rounded;
        break;
      case 'camera':
        iconData = Icons.camera_alt_rounded;
        break;
      case 'chat':
        iconData = Icons.chat_bubble_rounded;
        break;
      default:
        iconData = Icons.star_rounded;
    }

    // Using ValueKey to trigger FadeInSlide animation on page index changes
    return KeyedSubtree(
      key: ValueKey(page['title']),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInSlide(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _line),
                  boxShadow: [
                    BoxShadow(
                      color: _ink.withValues(alpha: 0.04),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line),
                  ),
                  child: Icon(
                    iconData,
                    size: 56,
                    color: _ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            FadeInSlide(
              delay: const Duration(milliseconds: 250),
              child: Text(
                page['title']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeInSlide(
              delay: const Duration(milliseconds: 400),
              child: Text(
                page['description']!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: _muted,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page Indicators
          Row(
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 28 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? _ink : _line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          // Next/Get Started Button
          GestureDetector(
            onTap: _nextPage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
