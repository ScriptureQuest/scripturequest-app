import 'package:flutter/material.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/providers/app_provider.dart' show AppThemeMode;

// Theme Packs v2.0
// Sacred Dark (existing) + Bedtime Calm + Olive Dawn + Ocean Deep

// A) Bedtime Calm (Purple theme polish)
// Surfaces
const Color _bedtimeBackground = Color(0xFF0E0A16); // near-black with purple tint
const Color _bedtimeCard = Color(0xFF171225);
const Color _bedtimeSurface = _bedtimeCard;

// Purple palette per spec
const Color _purplePrimary = Color(0xFF6D36FF); // base
const Color _purplePrimaryDark = Color(0xFF4B24B5); // darker for dark surfaces
const Color _purplePrimaryLight = Color(0xFF8B63FF); // lighter tint for icon bgs
const Color _purpleAccentCyan = Color(0xFF42CEDA); // softer cyan accent

// Softer success green in Purple mode
const Color _purpleSuccess = Color(0xFF42C973);

// B) Olive Dawn (earthy, manuscript-inspired)
const Color _oliveBackground = Color(0xFF0F1108); // dark olive
const Color _oliveCard = Color(0xFF1A1D12);
const Color _oliveSurface = _oliveCard;
const Color _olivePrimary = Color(0xFFA7C080); // sage green
const Color _oliveSecondary = Color(0xFFE4D7A3); // parchment gold

// C) Ocean Deep (cool modern blue)
const Color _oceanBackground = Color(0xFF07131F);
const Color _oceanCard = Color(0xFF0F1F2E);
const Color _oceanSurface = _oceanCard;
const Color _oceanPrimary = Color(0xFF5AB4FF); // ocean blue
const Color _oceanSecondary = Color(0xFF89E0FF); // teal accent

// Sacred Dark maps to the existing gamer dark theme
final ThemeData sacredDarkTheme = darkTheme;

// Bedtime Calm derives from Sacred Dark and acts as the Purple theme
final ThemeData bedtimeCalmTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: _bedtimeBackground,
  cardColor: _bedtimeCard,
  colorScheme: darkTheme.colorScheme.copyWith(
    primary: _purplePrimary,
    onPrimary: GamerColors.darkBackground,
    // Use accent cyan for secondary and tertiary to power small buttons/XP
    secondary: _purpleAccentCyan,
    tertiary: _purpleAccentCyan,
    surface: _bedtimeSurface,
    surfaceContainerHighest: _bedtimeCard,
    onSurface: GamerColors.textPrimary,
    onSurfaceVariant: GamerColors.textSecondary,
    // Card/border outline per spec (white at 6%)
    outline: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
    // Soften success in purple mode
    error: GamerColors.danger,
    shadow: Colors.black,
  ),
  appBarTheme: darkTheme.appBarTheme.copyWith(
    backgroundColor: Colors.transparent,
    foregroundColor: GamerColors.textPrimary,
  ),
  iconTheme: const IconThemeData(color: Colors.white70),
  dividerTheme: DividerThemeData(
    color: _purplePrimary.withValues(alpha: 0.10),
    thickness: 0.5,
  ),
  cardTheme: CardThemeData(
    color: _bedtimeCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
        width: 1,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _purplePrimary,
      foregroundColor: GamerColors.darkBackground,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: darkTheme.textTheme.labelLarge,
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) return _purplePrimary.withValues(alpha: 0.15);
        if (states.contains(WidgetState.hovered)) return _purplePrimary.withValues(alpha: 0.08);
        return null;
      }),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all<Color>(_purpleAccentCyan),
      textStyle: WidgetStateProperty.all<TextStyle?>(darkTheme.textTheme.labelLarge),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) return _purpleAccentCyan.withValues(alpha: 0.15);
        if (states.contains(WidgetState.hovered)) return _purpleAccentCyan.withValues(alpha: 0.08);
        return null;
      }),
      side: WidgetStateProperty.all<BorderSide>(BorderSide(color: _purpleAccentCyan.withValues(alpha: 0.4), width: 1)),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: _purpleAccentCyan,
      side: BorderSide(color: _purpleAccentCyan.withValues(alpha: 0.4), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) return _purpleAccentCyan.withValues(alpha: 0.15);
        if (states.contains(WidgetState.hovered)) return _purpleAccentCyan.withValues(alpha: 0.08);
        return null;
      }),
    ),
  ),
  bottomNavigationBarTheme: darkTheme.bottomNavigationBarTheme.copyWith(
    backgroundColor: const Color(0xFF120D1D),
    selectedItemColor: _purplePrimary,
    unselectedItemColor: Colors.white70,
    selectedIconTheme: const IconThemeData(size: 28),
  ),
).copyWith(
  // Theme extensions: expose Purple-specific accents to widgets without affecting other themes
  // Use a raw ThemeExtension list to avoid generic variance issues across extensions.
  extensions: <ThemeExtension<dynamic>>[
    PurpleUi(
      primary: _purplePrimary,
      primaryDark: _purplePrimaryDark,
      primaryLight: _purplePrimaryLight,
      accent: _purpleAccentCyan,
      success: _purpleSuccess,
      cardOutline: const Color(0xFFFFFFFF).withValues(alpha: 0.06),
      outlineActive: _purpleAccentCyan.withValues(alpha: 0.10),
      progressTrack: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
      progressFill: _purpleAccentCyan.withValues(alpha: 0.85),
      sectionTitle: const Color(0xFFFFFFFF).withValues(alpha: 0.90),
      sectionIcon: _purpleAccentCyan.withValues(alpha: 0.90),
      iconCircleAlpha: 0.15,
      supportIconCircleAlpha: 0.18,
    ),
  ],
);

// Olive Dawn: earthy, manuscript-inspired palette
final ThemeData oliveDawnTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: _oliveBackground,
  cardColor: _oliveCard,
  colorScheme: darkTheme.colorScheme.copyWith(
    primary: _olivePrimary,
    onPrimary: GamerColors.darkBackground,
    secondary: _oliveSecondary,
    surface: _oliveSurface,
    surfaceContainerHighest: _oliveCard,
    onSurface: GamerColors.textPrimary,
    onSurfaceVariant: GamerColors.textSecondary,
    outline: GamerColors.textTertiary,
  ),
  appBarTheme: darkTheme.appBarTheme,
  iconTheme: const IconThemeData(color: Colors.white70),
  dividerTheme: DividerThemeData(
    color: _olivePrimary.withValues(alpha: 0.12),
    thickness: 0.5,
  ),
  cardTheme: CardThemeData(
    color: _oliveCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(
        color: _olivePrimary.withValues(alpha: 0.18),
        width: 1,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _olivePrimary,
      foregroundColor: GamerColors.darkBackground,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: darkTheme.textTheme.labelLarge,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _olivePrimary,
      textStyle: darkTheme.textTheme.labelLarge,
    ),
  ),
  bottomNavigationBarTheme: darkTheme.bottomNavigationBarTheme.copyWith(
    backgroundColor: const Color(0xFF0E120A),
    selectedItemColor: _olivePrimary,
    unselectedItemColor: Colors.white70,
    selectedIconTheme: const IconThemeData(size: 28),
  ),
);

// Ocean Deep: cool, modern blue
final ThemeData oceanDeepTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: _oceanBackground,
  cardColor: _oceanCard,
  colorScheme: darkTheme.colorScheme.copyWith(
    primary: _oceanPrimary,
    onPrimary: GamerColors.darkBackground,
    secondary: _oceanSecondary,
    surface: _oceanSurface,
    surfaceContainerHighest: _oceanCard,
    onSurface: GamerColors.textPrimary,
    onSurfaceVariant: GamerColors.textSecondary,
    outline: GamerColors.textTertiary,
  ),
  appBarTheme: darkTheme.appBarTheme,
  iconTheme: const IconThemeData(color: Colors.white70),
  dividerTheme: DividerThemeData(
    color: _oceanPrimary.withValues(alpha: 0.12),
    thickness: 0.5,
  ),
  cardTheme: CardThemeData(
    color: _oceanCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(
        color: _oceanPrimary.withValues(alpha: 0.18),
        width: 1,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _oceanPrimary,
      foregroundColor: GamerColors.darkBackground,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: darkTheme.textTheme.labelLarge,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: _oceanPrimary,
      textStyle: darkTheme.textTheme.labelLarge,
    ),
  ),
  bottomNavigationBarTheme: darkTheme.bottomNavigationBarTheme.copyWith(
    backgroundColor: const Color(0xFF0A1926),
    selectedItemColor: _oceanPrimary,
    unselectedItemColor: Colors.white70,
    selectedIconTheme: const IconThemeData(size: 28),
  ),
);

ThemeData appThemeFor(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.bedtimeCalm:
      return bedtimeCalmTheme;
    case AppThemeMode.oliveDawn:
      return oliveDawnTheme;
    case AppThemeMode.oceanDeep:
      return oceanDeepTheme;
    case AppThemeMode.sacredDark:
    default:
      return sacredDarkTheme;
  }
}
