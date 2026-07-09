import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';

/// Reusable snackbar utilities for consistent messaging across the app
class SnackbarUtils {
  /// Show a success snackbar with a green background and checkmark icon
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showCustomNotification(
      context: context,
      title: 'Success',
      message: message,
      icon: Icons.check_circle_rounded,
      primaryColor: const Color(0xFF10B981), // Emerald green
      iconBgColor: const Color(0xFF10B981).withOpacity(0.1),
      duration: duration,
    );
  }

  /// Show an error snackbar with a red background and error icon
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showCustomNotification(
      context: context,
      title: 'Error',
      message: message,
      icon: Icons.error_outline_rounded,
      primaryColor: const Color(0xFFEF4444), // Coral red
      iconBgColor: const Color(0xFFEF4444).withOpacity(0.1),
      duration: duration,
    );
  }

  /// Show an info snackbar with a primary color background
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    IconData icon = Icons.info_outline_rounded,
  }) {
    _showCustomNotification(
      context: context,
      title: 'Info',
      message: message,
      icon: icon,
      primaryColor: AppColors.primary, // Brand purple
      iconBgColor: AppColors.primary.withOpacity(0.1),
      duration: duration,
    );
  }

  /// Show a bookmark toggle snackbar with dynamic icon and message
  static void showBookmark(
    BuildContext context,
    bool isBookmarked, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showCustomNotification(
      context: context,
      title: isBookmarked ? 'Bookmarked' : 'Unbookmarked',
      message: isBookmarked ? 'Item added to your bookmarks.' : 'Item removed from your bookmarks.',
      icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      primaryColor: AppColors.primary,
      iconBgColor: AppColors.primary.withOpacity(0.1),
      duration: duration,
    );
  }

  /// Show a warning snackbar with an orange/amber background
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showCustomNotification(
      context: context,
      title: 'Warning',
      message: message,
      icon: Icons.warning_amber_rounded,
      primaryColor: const Color(0xFFF59E0B), // Amber orange
      iconBgColor: const Color(0xFFF59E0B).withOpacity(0.1),
      duration: duration,
    );
  }

  /// Show a simple text-only snackbar
  static void showSimple(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    _showCustomNotification(
      context: context,
      title: 'Notification',
      message: message,
      icon: Icons.notifications_rounded,
      primaryColor: backgroundColor ?? const Color(0xFF64748B), // Slate gray
      iconBgColor: (backgroundColor ?? const Color(0xFF64748B)).withOpacity(0.1),
      duration: duration,
    );
  }

  /// Show a custom snackbar with full control
  static void showCustom(
    BuildContext context, {
    required Widget content,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    ShapeBorder? shape,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: behavior,
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
      ),
    );
  }

  /// Clear all current snackbars
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Internal helper to present the custom notification container
  static void _showCustomNotification({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color primaryColor,
    required Color iconBgColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 24,
        ),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: primaryColor.withOpacity(0.04),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Vertical accent indicator
                  Container(
                    width: 6,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 14),
                  // Styled Icon badge
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Text details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.3,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Dismiss button
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
