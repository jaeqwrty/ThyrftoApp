import 'package:flutter/material.dart';
/// Reusable snackbar utilities for consistent messaging across the app
class SnackbarUtils {
  static const Color _ink = Color(0xFF17131F);
  static const Color _muted = Color(0xFF6B6475);
  static const Color _line = Color(0xFFE5DFEC);
  static const Color _surface = Color(0xFFFBFAFC);
  static const Color _success = Color(0xFF2F7D62);
  static const Color _error = Color(0xFFD94A4A);
  static const Color _warning = Color(0xFFA8752A);

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
      primaryColor: _success,
      iconBgColor: _success.withValues(alpha: 0.1),
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
      primaryColor: _error,
      iconBgColor: _error.withValues(alpha: 0.1),
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
      primaryColor: _ink,
      iconBgColor: _ink.withValues(alpha: 0.08),
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
      message: isBookmarked
          ? 'Item added to your bookmarks.'
          : 'Item removed from your bookmarks.',
      icon: isBookmarked
          ? Icons.bookmark_rounded
          : Icons.bookmark_border_rounded,
      primaryColor: _ink,
      iconBgColor: _ink.withValues(alpha: 0.08),
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
      primaryColor: _warning,
      iconBgColor: _warning.withValues(alpha: 0.12),
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
      primaryColor: backgroundColor ?? _ink,
      iconBgColor: (backgroundColor ?? _ink).withValues(alpha: 0.08),
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
              borderRadius: BorderRadius.circular(14),
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
          left: 14,
          right: 14,
          bottom: 20,
        ),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _line,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.08),
                blurRadius: 22,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Vertical accent indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    width: 5,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 12),
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
                  const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _muted,
                              height: 1.3,
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
                      color: _muted,
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
