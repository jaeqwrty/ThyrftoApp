import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for userId fallback
import 'package:qr_flutter/qr_flutter.dart';
import 'package:thryfto/services/auth_service.dart';
import 'package:thryfto/services/seeding_service.dart'; // Correct service import
import 'package:thryfto/profileWidgets/profile_widgets.dart';
import 'package:thryfto/shared/auth_wrapper.dart';

class ProfileSettingsHandler {
  static void showSettingsMenu({
    required BuildContext context,
    required AuthService authService,
    required Map<String, dynamic> user, // Pass user map to get ID
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Dev Tools (Matching your screenshots) ---
            SettingsMenuItem(
              icon: Icons.cloud_upload,
              title: 'Seed Database (Dev Only)',
              onTap: () => _handleSeedDatabase(context, user),
            ),
            SettingsMenuItem(
              icon: Icons.refresh,
              title: 'Reset Database',
              subtitle: 'Clears all listings (Dev Only)',
              onTap: () => _handleResetDatabase(context, user),
            ),
            const Divider(),
            SettingsMenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => Navigator.pop(context),
            ),
            SettingsMenuItem(
              icon: Icons.info_outline,
              title: 'About Thryfto',
              onTap: () => Navigator.pop(context),
            ),
            const Divider(),
            SettingsMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context, authService);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Matching your screenshot {CB2AFF8D-8879-4F55-8B32-D9E85994B41F}
  static Future<void> _handleSeedDatabase(
      BuildContext context, Map<String, dynamic> user) async {
    final userId =
        user['id'] ?? user['uid'] ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seeding database...')),
      );

      await SeedingService().seedDatabase(userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database seeded successfully!')),
        );
      }
    }
  }

  // Matching your screenshot {46B5E245-4A88-4F86-A8BF-D3DBFFF8D0F8}
  static Future<void> _handleResetDatabase(
      BuildContext context, Map<String, dynamic> user) async {
    final userId =
        user['id'] ?? user['uid'] ?? FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resetting database...')),
      );

      await SeedingService().clearAllData(); // Correct method from your image

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset successfully!')),
        );
      }
    }
  }

  static Future<void> _handleLogout(
      BuildContext context, AuthService authService) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
      confirmText: 'Logout',
      confirmColor: Colors.red,
    );
    if (confirmed == true) {
      await authService.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
          (route) => false,
        );
      }
    }
  }

  static void handleShareProfile({
    required BuildContext context,
    required String userId,
    required String username,
  }) {
    final profileLink = "https://thryfto.app/profile/$userId";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Share Profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: Color(0xFF8B5CF6)),
              title: const Text("Copy Profile Link"),
              onTap: () {
                Clipboard.setData(ClipboardData(text: profileLink));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Link copied to clipboard!")),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: Color(0xFF8B5CF6)),
              title: const Text("Show QR Code"),
              onTap: () {
                Navigator.pop(context);
                _showQRCodeDialog(context, profileLink, username);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showQRCodeDialog(
      BuildContext context, String link, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("@$username",
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              // --- Real QR Code Generator ---
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF8B5CF6), // Matches your brand color
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Friends can scan this code with their camera to find your profile instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("Close", style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    );
  }
}
