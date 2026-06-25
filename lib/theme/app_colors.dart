import 'package:flutter/material.dart';

/// Central dark-mode design tokens for the app.
///
/// Keeping every colour in one place makes the dark theme consistent across
/// screens and avoids the scattered hard-coded hex values we had before.
class AppColors {
  AppColors._();

  // ── Surfaces ──────────────────────────────────────────────────────────────
  /// App / scaffold background (near-black).
  static const bg = Color(0xFF0E1014);

  /// Elevated surfaces: cards, app bar, bottom nav, sheets.
  static const surface = Color(0xFF181B22);

  /// Inputs, unselected chips, subtle fills.
  static const surfaceAlt = Color(0xFF22262F);

  /// Pressed / hovered / higher elevation.
  static const surfaceHigh = Color(0xFF2B313B);

  /// Hairline borders & dividers.
  static const border = Color(0xFF272B34);

  // ── Brand ─────────────────────────────────────────────────────────────────
  /// Vivid emerald accent that reads well on dark.
  static const primary = Color(0xFF2ED47A);

  /// Text/icon colour to place on top of [primary] fills.
  static const onPrimary = Color(0xFF06140C);

  /// Subtle green-tinted fill (use for soft highlights).
  static const primarySoft = Color(0x1F2ED47A); // ~12% primary

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFEFF1F5);
  static const textSecondary = Color(0xFF9BA3B2);
  static const textTertiary = Color(0xFF6A7280);

  // ── Accents ───────────────────────────────────────────────────────────────
  static const danger = Color(0xFFFF6B6B);
  static const promo = Color(0xFFFBBF24);
  static const promoSoft = Color(0x26FBBF24); // ~15% promo

  // ── Supermarket brand colours ──────────────────────────────────────────────
  /// Brightened slightly where needed so dark navy brands stay legible on a
  /// dark background.
  static Color supermarket(String s) {
    switch (s.toLowerCase()) {
      case 'spar':
        return const Color(0xFF1DA65A);
      case 'billa':
        return const Color(0xFFFFCC00);
      case 'hofer':
        return const Color(0xFF2E6FD6);
      case 'penny':
        return const Color(0xFFE5352B);
      case 'lidl':
        return const Color(0xFF2A7DE1);
      case 'mpreis':
        return const Color(0xFFE30613);
      default:
        return const Color(0xFF8A93A3);
    }
  }

  /// Whether text on top of a supermarket badge should be dark.
  static bool supermarketNeedsDarkText(String s) => s.toLowerCase() == 'billa';
}
