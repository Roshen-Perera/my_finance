import 'package:flutter/material.dart';

class AppColors {
  // Brand / Primary
  static const Color primary = Color(0xFF0D9488); // Deep Teal
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);

  // Financial Semantics
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeBgLight = Color(0xFFECFDF5);
  static const Color incomeBgDark = Color(0xFF064E3B);

  static const Color expense = Color(0xFFEF4444); // Coral Red
  static const Color expenseBgLight = Color(0xFFFEF2F2);
  static const Color expenseBgDark = Color(0xFF7F1D1D);

  static const Color transfer = Color(0xFF3B82F6); // Blue
  static const Color transferBgLight = Color(0xFFEFF6FF);
  static const Color transferBgDark = Color(0xFF1E3A8A);

  static const Color savings = Color(0xFF06B6D4); // Cyan / Teal
  static const Color savingsBgLight = Color(0xFFECFEFF);
  static const Color savingsBgDark = Color(0xFF164E63);

  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningBgLight = Color(0xFFFFFBEB);
  static const Color warningBgDark = Color(0xFF78350F);

  static const Color neutral = Color(0xFF64748B); // Slate Gray

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF0A0F1D);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Account Colors Palette for Account Icons / Badges
  static const List<Color> accountPalette = [
    Color(0xFF0D9488), // Teal
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFF14B8A6), // Mint
    Color(0xFF64748B), // Slate
  ];
}
