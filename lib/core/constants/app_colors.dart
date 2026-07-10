import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============================================
  // PRIMARY COLORS
  // ============================================

  /// Main brand color (Ink)
  static const Color primary = Color(0xFF17131F);

  /// Refined accent color used for small highlights.
  static const Color accent = Color(0xFFA8752A);

  /// Very light primary for backgrounds
  static Color primaryBackground = primary.withOpacity(0.1);

  /// Extra light primary for subtle backgrounds
  static Color primaryBackgroundLight = primary.withOpacity(0.05);

  // ============================================
  // BACKGROUND COLORS
  // ============================================

  /// Main background color
  static const Color background = Color(0xFFF6F3F8);

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
  static const Color textPrimary = Color(0xFF17131F);

  /// Secondary text color (grey)
  static const Color textSecondary = Color(0xFF6B6475);

  /// Tertiary text color (light grey)
  static const Color textTertiary = Color(0xFF8E8797);

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
  static const Color border = Color(0xFFE5DFEC);

  /// Border color light
  static const Color borderLight = Color(0xFFF4F1F7);

  /// Divider color
  static const Color divider = Color(0xFFE5DFEC);

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
