import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:thryfto/global/app_colors.dart';
import 'package:thryfto/services/auth_service.dart';
import 'package:thryfto/services/block_service.dart';
import 'package:thryfto/profileWidgets/profile_widgets.dart';
import 'package:thryfto/pages/blocked_users_page.dart';
import 'package:thryfto/shared/auth_wrapper.dart';

class ProfileSettingsHandler {
  static void showSettingsMenu({
    required BuildContext context,
    required AuthService authService,
    required Map<String, dynamic> user,
  }) {
    final blockService = BlockService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Privacy & Safety ---
            StreamBuilder<int>(
              stream: blockService.getBlockedUsersCountStream(),
              builder: (context, snapshot) {
                final blockedCount = snapshot.data ?? 0;
                return SettingsMenuItem(
                  icon: Icons.block,
                  title: 'Blocked Users',
                  subtitle: blockedCount > 0 ? '$blockedCount blocked' : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockedUsersPage(),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(),

            // --- Dev Tools --
            // SettingsMenuItem(
            //   icon: Icons.refresh,
            //   title: 'Reset Database',
            //   subtitle: 'Clears all listings (Dev Only)',
            //   onTap: () => _handleResetDatabase(context, user),
            // ),
            // const Divider(),

            // --- Support ---
            SettingsMenuItem(
              icon: Icons.info_outline,
              title: 'About Thryfto',
              onTap: () {
                // First, close the bottom sheet
                Navigator.pop(bottomSheetContext);
                // Then, show the custom dialog using the original context
                _showAboutDialog(context);
              },
            ),
            const Divider(),

            // --- Logout ---
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

  // static Future<void> _handleResetDatabase(
  //     BuildContext context, Map<String, dynamic> user) async {
  //   final userId =
  //       user['id'] ?? user['uid'] ?? FirebaseAuth.instance.currentUser?.uid;

  //   if (userId != null) {
  //     Navigator.pop(context);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Resetting database...')),
  //     );

  //     await SeedingService().clearAllData();

  //     if (context.mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Database reset successfully!')),
  //       );
  //     }
  //   }
  // }

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
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF8B5CF6),
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

  static void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo Header
              Container(
                width: double.infinity,
                // Change symmetric(vertical: 20) to this:
                padding: const EdgeInsets.only(top: 24, bottom: 4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/QualityThryftoLogo.png',
                    height: 90, // Adjusted height slightly for a tighter feel
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.shopping_bag,
                          size: 50, color: AppColors.primary);
                    },
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Sustainable fashion, one swap at a time.",
                      style: TextStyle(
                        fontSize:
                            15, // Slightly smaller font helps the "tight" look
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(
                        height:
                            8), // Control distance to the next paragraph here
                    const Text(
                      "Thryfto is a community marketplace where you can post, sell, and swap pre-loved items...",
                      style: TextStyle(height: 1.4, color: Colors.black87),
                    ),
                    const SizedBox(height: 15),

                    const Text(
                      "HOW IT WORKS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _FeatureRow(
                        icon: Icons.camera_alt_outlined,
                        text: "Upload item photos"),
                    const _FeatureRow(
                        icon: Icons.explore_outlined,
                        text: "Browse thrift posts"),
                    const _FeatureRow(
                        icon: Icons.chat_bubble_outline,
                        text: "Chat to negotiate and trade"),

                    const SizedBox(height: 5),
                    const Divider(),
                    const SizedBox(height: 5),
                    const Text(
                      "Our mission is to promote sustainable reuse and help local sellers through thrift culture.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Got it!",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widget for the rows
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(text,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
