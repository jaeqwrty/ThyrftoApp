import 'package:flutter/material.dart';
import 'package:thryfto/shared/app_colors.dart';

/// Reusable snackbar utilities for consistent messaging across the app
class SnackbarUtils {
  /// Show a success snackbar with a green background and checkmark icon
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show an error snackbar with a red background and error icon
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show an info snackbar with a primary color background
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    IconData icon = Icons.info_outline,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show a bookmark toggle snackbar with dynamic icon and message
  static void showBookmark(
    BuildContext context,
    bool isBookmarked, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isBookmarked ? 'Added to bookmarks' : 'Removed from bookmarks',
            ),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isBookmarked ? AppColors.primary : Colors.grey[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Show a simple text-only snackbar
  static void showSimple(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: behavior,
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
      ),
    );
  }

  /// Show a warning snackbar with an orange/amber background
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// Clear all current snackbars
  static void clearAll(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
}
