import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceHigh,
    required this.border,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.danger,
    required this.promo,
    required this.promoSoft,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceHigh;
  final Color border;
  final Color primary;
  final Color onPrimary;
  final Color primarySoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color danger;
  final Color promo;
  final Color promoSoft;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? dark;

  // Dark palette — same values as the original hardcoded palette
  static const dark = AppColors(
    bg: Color(0xFF0E1014),
    surface: Color(0xFF181B22),
    surfaceAlt: Color(0xFF22262F),
    surfaceHigh: Color(0xFF2B313B),
    border: Color(0xFF272B34),
    primary: Color(0xFF2ED47A),
    onPrimary: Color(0xFF06140C),
    primarySoft: Color(0x1F2ED47A),
    textPrimary: Color(0xFFEFF1F5),
    textSecondary: Color(0xFF9BA3B2),
    textTertiary: Color(0xFF6A7280),
    danger: Color(0xFFFF6B6B),
    promo: Color(0xFFFBBF24),
    promoSoft: Color(0x26FBBF24),
  );

  // Light palette
  static const light = AppColors(
    bg: Color(0xFFF5F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF0F4),
    surfaceHigh: Color(0xFFE4E7ED),
    border: Color(0xFFDDE0E8),
    primary: Color(0xFF2ED47A),
    onPrimary: Color(0xFF06140C),
    primarySoft: Color(0x1F2ED47A),
    textPrimary: Color(0xFF0D1117),
    textSecondary: Color(0xFF4B5563),
    textTertiary: Color(0xFF9CA3AF),
    danger: Color(0xFFEF4444),
    promo: Color(0xFFD97706),
    promoSoft: Color(0x26D97706),
  );

  // Keep supermarket brand colors as static (they are branding, not theme-dependent)
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

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceHigh,
    Color? border,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? danger,
    Color? promo,
    Color? promoSoft,
  }) =>
      AppColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        surfaceHigh: surfaceHigh ?? this.surfaceHigh,
        border: border ?? this.border,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        primarySoft: primarySoft ?? this.primarySoft,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        danger: danger ?? this.danger,
        promo: promo ?? this.promo,
        promoSoft: promoSoft ?? this.promoSoft,
      );

  @override
  AppColors lerp(AppColors? other, double t) => AppColors(
        bg: Color.lerp(bg, other?.bg, t)!,
        surface: Color.lerp(surface, other?.surface, t)!,
        surfaceAlt: Color.lerp(surfaceAlt, other?.surfaceAlt, t)!,
        surfaceHigh: Color.lerp(surfaceHigh, other?.surfaceHigh, t)!,
        border: Color.lerp(border, other?.border, t)!,
        primary: Color.lerp(primary, other?.primary, t)!,
        onPrimary: Color.lerp(onPrimary, other?.onPrimary, t)!,
        primarySoft: Color.lerp(primarySoft, other?.primarySoft, t)!,
        textPrimary: Color.lerp(textPrimary, other?.textPrimary, t)!,
        textSecondary: Color.lerp(textSecondary, other?.textSecondary, t)!,
        textTertiary: Color.lerp(textTertiary, other?.textTertiary, t)!,
        danger: Color.lerp(danger, other?.danger, t)!,
        promo: Color.lerp(promo, other?.promo, t)!,
        promoSoft: Color.lerp(promoSoft, other?.promoSoft, t)!,
      );
}
