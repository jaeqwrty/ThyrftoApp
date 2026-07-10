import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/constants/app_constants.dart';

/// Utility class for common dialog widgets
class CommonDialogs {
  CommonDialogs._();

  /// Show a loading dialog with circular progress indicator
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlayLight,
      builder: (context) => Center(
        child: Container(
          padding: AppConstants.paddingAllXXL,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppConstants.borderRadiusXL,
            border: Border.all(color: AppColors.border),
          ),
          child: const CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }

  /// Show a confirmation dialog with customizable title, message, and actions
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusXL,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  confirmColor ?? (isDangerous ? Colors.red : null),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Show a floating delete confirmation dialog with icon
  static Future<bool?> showDeleteConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlayDark,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusDialog,
        ),
        elevation: AppConstants.elevationHigh,
        child: Container(
          padding: AppConstants.paddingAllXXL,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppConstants.paddingAllXL,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: AppConstants.iconSizeXXL, color: Colors.red),
              ),
              const SizedBox(height: AppConstants.spaceXXL),
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeXXL,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spaceL),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeM,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spaceXXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontSize: AppConstants.fontSizeL,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceL),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: AppConstants.elevationNone,
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontSize: AppConstants.fontSizeL,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a result dialog (success or error) with icon and message
  static void showResultDialog(
    BuildContext context, {
    required bool success,
    required String successTitle,
    required String successMessage,
    required String failTitle,
    required String failMessage,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.borderRadiusDialog,
        ),
        child: Container(
          padding: AppConstants.paddingAllXXL,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppConstants.paddingAllXL,
                decoration: BoxDecoration(
                  color: success
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_outline : Icons.error_outline,
                  size: AppConstants.iconSizeXXL,
                  color: success ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: AppConstants.spaceXL),
              Text(
                success ? successTitle : failTitle,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeXXL,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spaceM),
              Text(
                success ? successMessage : failMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeM,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spaceXXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success ? AppColors.primary : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: AppConstants.elevationNone,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: AppConstants.fontSizeL,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show an image preview dialog
  static void showImagePreviewDialog(
    BuildContext context,
    String imageUrl,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: AppConstants.iconSizeXXL,
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: AppConstants.paddingAllM,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: AppConstants.iconSizeL,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
