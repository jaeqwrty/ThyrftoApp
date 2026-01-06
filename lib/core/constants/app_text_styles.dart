import 'package:flutter/material.dart';
import 'package:thryfto/core/constants/app_colors.dart';
import 'package:thryfto/core/constants/app_constants.dart';

/// Common text styles used throughout the app
class AppTextStyles {
  AppTextStyles._();

  // ============================================
  // HEADING STYLES
  // ============================================

  /// Large heading (28px, bold)
  static const TextStyle headingLarge = TextStyle(
    fontSize: AppConstants.fontSizeXHuge,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Medium heading (24px, bold)
  static const TextStyle headingMedium = TextStyle(
    fontSize: AppConstants.fontSizeHuge,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Small heading (20px, bold)
  static const TextStyle headingSmall = TextStyle(
    fontSize: AppConstants.fontSizeXXL,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Dialog title (22px, bold)
  static const TextStyle dialogTitle = TextStyle(
    fontSize: AppConstants.fontSizeXXXL,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  // ============================================
  // SUBTITLE STYLES
  // ============================================

  /// Subtitle large (18px, w600)
  static const TextStyle subtitleLarge = TextStyle(
    fontSize: AppConstants.fontSizeXL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Subtitle medium (16px, w600)
  static const TextStyle subtitleMedium = TextStyle(
    fontSize: AppConstants.fontSizeL,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Subtitle small (14px, w600)
  static const TextStyle subtitleSmall = TextStyle(
    fontSize: AppConstants.fontSizeM,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ============================================
  // BODY STYLES
  // ============================================

  /// Body large (16px, normal)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppConstants.fontSizeL,
    color: AppColors.textPrimary,
  );

  /// Body medium (14px, normal)
  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppConstants.fontSizeM,
    color: AppColors.textPrimary,
  );

  /// Body small (12px, normal)
  static const TextStyle bodySmall = TextStyle(
    fontSize: AppConstants.fontSizeS,
    color: AppColors.textPrimary,
  );

  /// Body with height (14px, line height 1.4)
  static const TextStyle bodyWithHeight = TextStyle(
    fontSize: AppConstants.fontSizeM,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ============================================
  // CAPTION STYLES
  // ============================================

  /// Caption (12px, grey)
  static TextStyle caption = TextStyle(
    fontSize: AppConstants.fontSizeS,
    color: Colors.grey[600],
  );

  /// Caption small (11px, grey)
  static TextStyle captionSmall = TextStyle(
    fontSize: AppConstants.fontSizeXS,
    color: Colors.grey[500],
  );

  /// Timestamp (11px, grey)
  static TextStyle timestamp = TextStyle(
    fontSize: AppConstants.fontSizeXS,
    color: Colors.grey[500],
  );

  // ============================================
  // BUTTON STYLES
  // ============================================

  /// Button text (16px, w600)
  static const TextStyle button = TextStyle(
    fontSize: AppConstants.fontSizeL,
    fontWeight: FontWeight.w600,
  );

  /// Small button text (14px, w600)
  static const TextStyle buttonSmall = TextStyle(
    fontSize: AppConstants.fontSizeM,
    fontWeight: FontWeight.w600,
  );

  /// Button with icon (16px, w600)
  static const TextStyle buttonWithIcon = TextStyle(
    fontSize: AppConstants.fontSizeL,
    fontWeight: FontWeight.w600,
    fontFamily: 'SF Pro Display',
  );

  // ============================================
  // LABEL STYLES
  // ============================================

  /// Form label (14px, w600)
  static const TextStyle formLabel = TextStyle(
    fontSize: AppConstants.fontSizeM,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Section label (14px, w600)
  static const TextStyle sectionLabel = TextStyle(
    fontSize: AppConstants.fontSizeM,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  // ============================================
  // PRICE STYLES
  // ============================================

  /// Price large (23px, bold, primary)
  static const TextStyle priceLarge = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  /// Price medium (16px, bold, primary)
  static const TextStyle priceMedium = TextStyle(
    fontSize: AppConstants.fontSizeL,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // ============================================
  // TAG/BADGE STYLES
  // ============================================

  /// Badge text (11px, w600)
  static const TextStyle badge = TextStyle(
    fontSize: AppConstants.fontSizeXS,
    fontWeight: FontWeight.w600,
  );

  /// Small badge text (10px, bold)
  static const TextStyle badgeSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );

  // ============================================
  // SPECIAL STYLES
  // ============================================

  /// Error text (14px, red)
  static TextStyle error = TextStyle(
    fontSize: AppConstants.fontSizeM,
    color: Colors.red.shade700,
  );

  /// Success text (14px, green)
  static TextStyle success = TextStyle(
    fontSize: AppConstants.fontSizeM,
    color: Colors.green.shade700,
  );

  /// Warning text (14px, orange)
  static TextStyle warning = TextStyle(
    fontSize: AppConstants.fontSizeM,
    color: Colors.orange.shade700,
  );

  /// Hint text (14px, light grey)
  static TextStyle hint = TextStyle(
    fontSize: AppConstants.fontSizeM,
    color: Colors.grey[400],
  );

  /// Link text (14px, primary, underline)
  static const TextStyle link = TextStyle(
    fontSize: AppConstants.fontSizeM,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  // ============================================
  // MESSAGE/CHAT STYLES
  // ============================================

  /// Message bubble text (15px)
  static const TextStyle messageBubble = TextStyle(
    fontSize: AppConstants.fontSizeML,
    height: 1.4,
  );

  /// Message time (11px, grey)
  static TextStyle messageTime = TextStyle(
    fontSize: AppConstants.fontSizeXS,
    color: Colors.grey[500],
  );

  // ============================================
  // TITLE/USERNAME STYLES
  // ============================================

  /// Username (16px, grey)
  static TextStyle username = TextStyle(
    fontSize: AppConstants.fontSizeL,
    color: Colors.grey[600],
  );

  /// Title bold (16px, bold)
  static const TextStyle titleBold = TextStyle(
    fontSize: AppConstants.fontSizeL,
    fontWeight: FontWeight.bold,
  );

  /// Title medium (14px, w500)
  static const TextStyle titleMedium = TextStyle(
    fontSize: AppConstants.fontSizeM,
    fontWeight: FontWeight.w500,
  );

  // ============================================
  // LIST/MODAL STYLES
  // ============================================

  /// Modal title (16px, w600)
  static const TextStyle modalTitle = TextStyle(
    fontSize: AppConstants.fontSizeL,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  /// List tile title (15px, w500)
  static const TextStyle listTileTitle = TextStyle(
    fontSize: AppConstants.fontSizeML,
    fontWeight: FontWeight.w500,
  );

  /// List tile subtitle (12px, grey)
  static TextStyle listTileSubtitle = TextStyle(
    fontSize: AppConstants.fontSizeS,
    color: Colors.grey[600],
  );
}
