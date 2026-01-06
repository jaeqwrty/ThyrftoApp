import 'package:flutter/material.dart';

/// App-wide constants for spacing, sizing, and other layout values
class AppConstants {
  AppConstants._();

  // ============================================
  // SPACING CONSTANTS
  // ============================================

  /// Small spacing (8px)
  static const double spaceS = 8.0;

  /// Medium spacing (12px)
  static const double spaceM = 12.0;

  /// Large spacing (16px)
  static const double spaceL = 16.0;

  /// Extra large spacing (20px)
  static const double spaceXL = 20.0;

  /// Extra extra large spacing (24px)
  static const double spaceXXL = 24.0;

  // ============================================
  // PADDING CONSTANTS
  // ============================================

  /// All-around small padding (8px)
  static const EdgeInsets paddingAllS = EdgeInsets.all(8);

  /// All-around medium padding (12px)
  static const EdgeInsets paddingAllM = EdgeInsets.all(12);

  /// All-around large padding (16px)
  static const EdgeInsets paddingAllL = EdgeInsets.all(16);

  /// All-around extra large padding (20px)
  static const EdgeInsets paddingAllXL = EdgeInsets.all(20);

  /// All-around extra extra large padding (24px)
  static const EdgeInsets paddingAllXXL = EdgeInsets.all(24);

  /// List item padding (horizontal: 20px, vertical: 8px)
  static const EdgeInsets paddingListItem =
      EdgeInsets.symmetric(horizontal: 20, vertical: 8);

  // ============================================
  // BORDER RADIUS CONSTANTS
  // ============================================

  /// Small radius (4px)
  static const double radiusS = 4.0;

  /// Medium radius (8px)
  static const double radiusM = 8.0;

  /// Large radius (12px)
  static const double radiusL = 12.0;

  /// Extra large radius (16px)
  static const double radiusXL = 16.0;

  /// Extra extra large radius (20px)
  static const double radiusXXL = 20.0;

  /// Rounded (28px) - for dialogs
  static const double radiusRounded = 28.0;

  /// Circular (for buttons, pills)
  static const double radiusCircular = 25.0;

  /// BorderRadius large
  static const BorderRadius borderRadiusL =
      BorderRadius.all(Radius.circular(radiusL));

  /// BorderRadius extra large
  static const BorderRadius borderRadiusXL =
      BorderRadius.all(Radius.circular(radiusXL));

  /// BorderRadius for dialogs
  static const BorderRadius borderRadiusDialog =
      BorderRadius.all(Radius.circular(radiusRounded));

  /// BorderRadius for buttons
  static const BorderRadius borderRadiusButton =
      BorderRadius.all(Radius.circular(radiusCircular));

  /// BorderRadius for modals (top only)
  static const BorderRadius borderRadiusModal =
      BorderRadius.vertical(top: Radius.circular(radiusXXL));

  // ============================================
  // SIZE CONSTANTS
  // ============================================

  /// Icon size medium (20px)
  static const double iconSizeM = 20.0;

  /// Icon size large (24px)
  static const double iconSizeL = 24.0;

  /// Icon size extra extra large (48px)
  static const double iconSizeXXL = 48.0;

  /// Modal drag handle width (40px)
  static const double modalDragHandleWidth = 40.0;

  /// Modal drag handle height (4px)
  static const double modalDragHandleHeight = 4.0;

  // ============================================
  // FONT SIZE CONSTANTS
  // ============================================

  /// Extra small font (11px)
  static const double fontSizeXS = 11.0;

  /// Small font (12px)
  static const double fontSizeS = 12.0;

  /// Medium font (14px)
  static const double fontSizeM = 14.0;

  /// Medium large font (15px)
  static const double fontSizeML = 15.0;

  /// Large font (16px)
  static const double fontSizeL = 16.0;

  /// Extra large font (18px)
  static const double fontSizeXL = 18.0;

  /// Extra extra large font (20px)
  static const double fontSizeXXL = 20.0;

  /// Extra extra extra large font (22px)
  static const double fontSizeXXXL = 22.0;

  /// Huge font (24px)
  static const double fontSizeHuge = 24.0;

  /// Extra huge font (28px)
  static const double fontSizeXHuge = 28.0;

  // ============================================
  // ELEVATION CONSTANTS
  // ============================================

  /// No elevation
  static const double elevationNone = 0.0;

  /// High elevation (8px)
  static const double elevationHigh = 8.0;

  // ============================================
  // STROKE WIDTH CONSTANTS
  // ============================================

  /// Normal stroke (2px)
  static const double strokeNormal = 2.0;
}
