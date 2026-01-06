import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================

  /// Main brand color (Purple)
  static const Color primary = Color.fromRGBO(139, 92, 246, 1);

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

  /// White text
  static const Color textWhite = Colors.white;

  // ============================================
  // ACCENT COLORS
  // ============================================

  /// Success/Green color
  static const Color success = Colors.green;

  /// Error/Red color
  static const Color error = Colors.red;
  static Color errorLight = Colors.red.shade50;

  /// Warning/Orange color
  static const Color warning = Colors.orange;

  /// Info/Blue color
  static const Color info = Colors.blue;

  // ============================================
  // UI ELEMENT COLORS
  // ============================================

  /// Border color
  static Color border = Colors.grey[300]!;

  /// Border color light
  static Color borderLight = Colors.grey[200]!;

  /// Divider color
  static Color divider = Colors.grey[100]!;

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Like/Favorite color
  static const Color like = Colors.red;

  /// Star/Rating color
  static const Color rating = Colors.amber;

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
}
