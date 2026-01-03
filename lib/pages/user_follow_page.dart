import 'package:flutter/material.dart';
import 'package:thryfto/shared/app_colors.dart';
import 'package:thryfto/pages/user_profile_page.dart';

class UserListPage extends StatelessWidget {
  final String title;
  final Stream<List<Map<String, dynamic>>> userStream;
  final Map<String, dynamic> currentUser; // Your profile data needed for the follow button

  const UserListPage({
    super.key,
    required this.title,
    required this.userStream,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
             color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            )),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0, // Makes the header seamless
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Text("No users found",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            );
          }

          // ListView.builder removes the lines between items
          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final user = users[index];
              final fullName = user['fullName'] ?? user['full_name'] ?? 'User';
              final username = user['username'] ?? 'unknown';
              final imageUrl = user['profileImageUrl'] as String?;
              
              // Get the ID of the user in the list
              final targetUserId = user['uid'] ?? user['id'] ?? '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.backgroundGreyDark,
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                      ? NetworkImage(imageUrl)
                      : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? Text(fullName[0].toUpperCase())
                      : null,
                ),
                title: Text(fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('@$username',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                onTap: () {
                  // CORRECT REDIRECTION
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        userId: targetUserId,    // Pass the ID of the user clicked
                        currentUser: currentUser, // Pass YOUR data (for follow logic)
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}