import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';

/// A reusable widget that displays a statistic in a column format
/// Used in profile pages to show posts, followers, and following counts
class ProfileStatColumn extends StatelessWidget {
  final String value;
  final String label;
  final bool modern;

  const ProfileStatColumn({
    super.key,
    required this.value,
    required this.label,
    this.modern = false,
  });

  @override
  Widget build(BuildContext context) {
    if (modern) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5DFEC)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF17131F),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6B6475),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

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
