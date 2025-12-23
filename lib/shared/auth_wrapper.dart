import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thryfto/services/auth_service.dart';
import 'package:thryfto/pages/home_page.dart';
import 'package:thryfto/pages/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // User is logged in, fetch their profile
          return FutureBuilder<Map<String, dynamic>?>(
            future: authService.getUserProfile(user.uid),
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

              return HomeScreen(user: profileSnapshot.data!);
            },
          );
        }

        // User is not logged in
        return const LoginScreen();
      },
    );
  }
}
