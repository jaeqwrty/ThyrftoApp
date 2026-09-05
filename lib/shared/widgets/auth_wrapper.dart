import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/shared/widgets/main_navigation.dart';
import 'package:thryfto/core/providers/auth_providers.dart';
import 'package:thryfto/features/auth/pages/login_page.dart';
import 'package:thryfto/features/auth/pages/onboarding_page.dart';
import 'package:thryfto/shared/widgets/skeleton_loaders.dart';
import 'package:thryfto/shared/widgets/deep_link_gate.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (user) {
        if (user != null) {
          // User is logged in, fetch their profile
          return FutureBuilder<Map<String, dynamic>?>(
            future: ref.read(authServiceProvider).getUserProfile(user.uid),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFFF6F3F8),
                  body: SafeArea(
                    child: PostCardListSkeleton(),
                  ),
                );
              }

              if (profileSnapshot.hasError || profileSnapshot.data == null) {
                // If profile fetch fails, fallback to basic info or logout
                return const LoginScreen();
              }

              final userData = profileSnapshot.data!;
              final bool onboardingCompleted =
                  userData['onboardingCompleted'] ?? true;

              if (!onboardingCompleted) {
                return const OnboardingPage();
              }

              return DeepLinkGate(
                user: userData,
                child: MainNavigation(user: userData),
              );
            },
          );
        }

        // User is not logged in
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF6F3F8),
        body: SafeArea(
          child: PostCardListSkeleton(),
        ),
      ),
      error: (error, stack) => const LoginScreen(),
    );
  }
}
