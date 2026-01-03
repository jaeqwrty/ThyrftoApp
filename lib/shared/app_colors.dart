import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================

  /// Main brand color (Purple)
  static const Color primary = Color.fromRGBO(139, 92, 246, 1);

  /// Lighter shade of primary color
  static const Color primaryLight = Color.fromRGBO(217, 70, 239, 1);

  /// Dark shade of primary color
  static const Color primaryDark = Color(0xFF7C3AED);

  /// Very light primary for backgrounds
  static Color primaryBackground = primary.withOpacity(0.1);

  /// Extra light primary for subtle backgrounds
  static Color primaryBackgroundLight = primary.withOpacity(0.05);

  // ============================================
  // BACKGROUND COLORS
  // ============================================

  /// Main background color
  static const Color background = Color(0xFFF5F5F7);

  /// White background
  static const Color backgroundWhite = Colors.white;

  /// Light grey background
  static Color backgroundGrey = Colors.grey[50]!;

  /// Darker grey background
  static Color backgroundGreyDark = Colors.grey[100]!;

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Primary text color (black)
  static const Color textPrimary = Colors.black87;

  /// Secondary text color (grey)
  static Color textSecondary = Colors.grey[600]!;

  /// Tertiary text color (light grey)
  static Color textTertiary = Colors.grey[500]!;

  /// Hint text color
  static Color textHint = Colors.grey[400]!;

  /// White text
  static const Color textWhite = Colors.white;

  // ============================================
  // ACCENT COLORS
  // ============================================

  /// Success/Green color
  static const Color success = Colors.green;
  static Color successLight = Colors.green.shade50;
  static Color successDark = Colors.green.shade700;

  /// Error/Red color
  static const Color error = Colors.red;
  static Color errorLight = Colors.red.shade50;
  static Color errorDark = Colors.red.shade700;

  /// Warning/Orange color
  static const Color warning = Colors.orange;
  static Color warningLight = Colors.orange.shade50;
  static Color warningDark = Colors.orange.shade700;

  /// Info/Blue color
  static const Color info = Colors.blue;
  static Color infoLight = Colors.blue.shade50;
  static Color infoDark = Colors.blue.shade700;

  // ============================================
  // UI ELEMENT COLORS
  // ============================================

  /// Border color
  static Color border = Colors.grey[300]!;

  /// Border color light
  static Color borderLight = Colors.grey[200]!;

  /// Divider color
  static Color divider = Colors.grey[100]!;

  /// Icon color
  static Color icon = Colors.grey[400]!;

  /// Icon color dark
  static const Color iconDark = Colors.black87;

  // ============================================
  // CATEGORY/TAG COLORS
  // ============================================

  /// Purple tag background
  static Color tagPurpleBackground = Colors.purple.shade50;
  static const Color tagPurpleText = Color(0xFF8B5CF6);

  /// Green tag background
  static Color tagGreenBackground = Colors.green.shade50;
  static Color tagGreenText = Colors.green.shade700;

  /// Blue tag background
  static Color tagBlueBackground = Colors.blue.shade50;
  static Color tagBlueText = Colors.blue.shade700;

  /// Orange tag background
  static Color tagOrangeBackground = Colors.orange.shade50;
  static Color tagOrangeText = Colors.orange.shade700;

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Like/Favorite color
  static const Color like = Colors.red;

  /// Star/Rating color
  static const Color rating = Colors.amber;

  /// Location color
  static const Color location = Color(0xFF8B5CF6);

  /// Sold badge color
  static Color soldBadge = Colors.black.withOpacity(0.7);

  // ============================================
  // SHADOW COLORS
  // ============================================

  /// Light shadow
  static Color shadowLight = Colors.black.withOpacity(0.03);

  /// Medium shadow
  static Color shadowMedium = Colors.black.withOpacity(0.05);

  /// Dark shadow
  static Color shadowDark = Colors.black.withOpacity(0.1);

  // ============================================
  // OVERLAY COLORS
  // ============================================

  static Color overlayDark = Colors.black54;

  static Color overlayLight = Colors.black26;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
