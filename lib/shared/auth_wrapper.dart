import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thryfto/commonWidgets/main_navigation.dart';
import 'package:thryfto/providers/auth_providers.dart';
import 'package:thryfto/pages/login_page.dart';
import 'package:thryfto/pages/onboarding_page.dart';

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
                  body: Center(
                    child: CircularProgressIndicator(),
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

              return MainNavigation(user: userData);
            },
          );
        }

        // User is not logged in
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => const LoginScreen(),
    );
  }
}
