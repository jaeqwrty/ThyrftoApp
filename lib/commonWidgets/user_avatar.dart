/// User avatar with initial letter
import 'package:flutter/material.dart';
import 'package:thryfto/shared/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String username;
  final double radius;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.username,
    this.radius = 28,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? AppColors.primary,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
