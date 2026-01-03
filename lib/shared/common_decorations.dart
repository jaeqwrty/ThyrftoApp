import 'package:flutter/material.dart';
import 'package:thryfto/shared/app_colors.dart';
import 'package:thryfto/shared/app_constants.dart';

/// Common decoration utilities for consistent UI styling
class CommonDecorations {
  CommonDecorations._();

  // ============================================
  // BOX DECORATIONS
  // ============================================

  /// Standard card decoration with white background and subtle shadow
  static BoxDecoration card({
    Color? backgroundColor,
    double? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.radiusL),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
    );
  }

  /// Container decoration with shadow
  static BoxDecoration containerWithShadow({
    Color? backgroundColor,
    double? borderRadius,
    double? shadowOpacity,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.radiusL),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(shadowOpacity ?? 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Modal bottom sheet decoration (rounded top corners)
  static BoxDecoration modalSheet({Color? backgroundColor}) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: AppConstants.borderRadiusModal,
    );
  }

  /// Circular badge decoration
  static BoxDecoration circleBadge({
    required Color backgroundColor,
    Border? border,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.circle,
      border: border,
    );
  }

  /// Rounded badge/tag decoration
  static BoxDecoration roundedBadge({
    required Color backgroundColor,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.radiusS),
    );
  }

  /// Info box decoration (for warnings, errors, success messages)
  static BoxDecoration infoBox({
    required Color backgroundColor,
    required Color borderColor,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.radiusL),
      border: Border.all(color: borderColor),
    );
  }

  /// Image container with rounded corners
  static BoxDecoration imageContainer({
    double? borderRadius,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.grey[100],
      borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.radiusM),
      border: Border.all(color: Colors.grey[300]!, width: 2),
    );
  }

  /// Delete button circle decoration (red background)
  static BoxDecoration deleteButton() {
    return const BoxDecoration(
      color: Colors.red,
      shape: BoxShape.circle,
    );
  }

  /// Icon container decoration with color and rounded corners
  static BoxDecoration iconContainer({
    required Color backgroundColor,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius ?? AppConstants.radiusM),
    );
  }

  // ============================================
  // BOX SHADOWS
  // ============================================

  /// Light shadow
  static List<BoxShadow> lightShadow() {
    return [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Medium shadow
  static List<BoxShadow> mediumShadow() {
    return [
      BoxShadow(
        color: AppColors.shadowMedium,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Dark shadow
  static List<BoxShadow> darkShadow() {
    return [
      BoxShadow(
        color: AppColors.shadowDark,
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Floating shadow (for dialogs)
  static List<BoxShadow> floatingShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // ============================================
  // INPUT DECORATIONS
  // ============================================

  /// Standard input decoration for text fields
  static InputDecoration inputDecoration({
    required String hintText,
    IconData? prefixIcon,
    String? prefixText,
    int? maxLength,
    Color? fillColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: AppConstants.fontSizeM,
        color: Colors.grey[400],
      ),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon,
              size: AppConstants.iconSizeM, color: Colors.grey[400])
          : null,
      prefixText: prefixText,
      border: OutlineInputBorder(
        borderRadius: AppConstants.borderRadiusL,
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: fillColor ?? Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
    );
  }

  // ============================================
  // BUTTON STYLES
  // ============================================

  /// Primary button style
  static ButtonStyle primaryButton({
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusButton,
      ),
      elevation: AppConstants.elevationNone,
    );
  }

  /// Outlined button style
  static ButtonStyle outlinedButton({Color? foregroundColor}) {
    return OutlinedButton.styleFrom(
      foregroundColor: foregroundColor ?? AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusButton,
      ),
    );
  }

  /// Text button style
  static ButtonStyle textButton({Color? foregroundColor}) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor ?? AppColors.primary,
    );
  }

  /// Danger button style (for delete actions)
  static ButtonStyle dangerButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusL,
      ),
      elevation: AppConstants.elevationNone,
    );
  }
}
