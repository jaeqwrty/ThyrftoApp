import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';

/// A reusable widget that displays a statistic in a column format
/// Used in profile pages to show posts, followers, and following counts
class ProfileStatColumn extends StatelessWidget {
  final String value;
  final String label;

  const ProfileStatColumn({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
