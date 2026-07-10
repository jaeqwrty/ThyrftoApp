import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';

/// Tag/Badge widget for displaying size, condition, etc.
class TagBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const TagBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.fontSize = 11,
  });

  factory TagBadge.size(String text) {
    return TagBadge(
      text: text,
      backgroundColor: AppColors.accent.withValues(alpha: 0.12),
      textColor: AppColors.primary,
    );
  }

  factory TagBadge.condition(String text) {
    return TagBadge(
      text: text,
      backgroundColor: Colors.green.shade50,
      textColor: Colors.green.shade700,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
