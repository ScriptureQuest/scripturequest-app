import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GamerColors {
  static const darkBackground = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF121620);
  static const darkCard = Color(0xFF1A1F2E);
  
  static const neonCyan = Color(0xFF00F0FF);
  static const neonPurple = Color(0xFFB600FF);
  static const neonGold = Color(0xFFFFD54F);
  static const neonGreen = Color(0xFF39FF14);
  static const neonPink = Color(0xFFFF006E);
  
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B8C8);
  static const textTertiary = Color(0xFF6B7280);
  
  static const accent = neonCyan;
  static const accentSecondary = neonPurple;
  static const success = neonGreen;
  static const danger = neonPink;
}

// =============================================================================
// THEME EXTENSIONS
// =============================================================================

/// Purple-only UI overrides. When present on Theme.of(context), widgets can opt-in
/// to polished visuals without affecting other themes.
class PurpleUi extends ThemeExtension<PurpleUi> {
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color accent; // cyan accent
  final Color success; // softened green for purple mode
  final Color cardOutline; // normal outline
  final Color outlineActive; // hover/press outline
  final Color progressTrack;
  final Color progressFill;
  final Color sectionTitle;
  final Color sectionIcon;
  final double iconCircleAlpha; // 0.15 spec for tools icon backgrounds
  final double supportIconCircleAlpha; // 0.18 spec

  const PurpleUi({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.accent,
    required this.success,
    required this.cardOutline,
    required this.outlineActive,
    required this.progressTrack,
    required this.progressFill,
    required this.sectionTitle,
    required this.sectionIcon,
    required this.iconCircleAlpha,
    required this.supportIconCircleAlpha,
  });

  @override
  ThemeExtension<PurpleUi> copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? accent,
    Color? success,
    Color? cardOutline,
    Color? outlineActive,
    Color? progressTrack,
    Color? progressFill,
    Color? sectionTitle,
    Color? sectionIcon,
    double? iconCircleAlpha,
    double? supportIconCircleAlpha,
  }) {
    return PurpleUi(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      cardOutline: cardOutline ?? this.cardOutline,
      outlineActive: outlineActive ?? this.outlineActive,
      progressTrack: progressTrack ?? this.progressTrack,
      progressFill: progressFill ?? this.progressFill,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      sectionIcon: sectionIcon ?? this.sectionIcon,
      iconCircleAlpha: iconCircleAlpha ?? this.iconCircleAlpha,
      supportIconCircleAlpha: supportIconCircleAlpha ?? this.supportIconCircleAlpha,
    );
  }

  @override
  ThemeExtension<PurpleUi> lerp(covariant ThemeExtension<PurpleUi>? other, double t) {
    if (other is! PurpleUi) return this;
    Color lerpColor(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return PurpleUi(
      primary: lerpColor(primary, other.primary),
      primaryDark: lerpColor(primaryDark, other.primaryDark),
      primaryLight: lerpColor(primaryLight, other.primaryLight),
      accent: lerpColor(accent, other.accent),
      success: lerpColor(success, other.success),
      cardOutline: lerpColor(cardOutline, other.cardOutline),
      outlineActive: lerpColor(outlineActive, other.outlineActive),
      progressTrack: lerpColor(progressTrack, other.progressTrack),
      progressFill: lerpColor(progressFill, other.progressFill),
      sectionTitle: lerpColor(sectionTitle, other.sectionTitle),
      sectionIcon: lerpColor(sectionIcon, other.sectionIcon),
      iconCircleAlpha: iconCircleAlpha + (other.iconCircleAlpha - iconCircleAlpha) * t,
      supportIconCircleAlpha: supportIconCircleAlpha + (other.supportIconCircleAlpha - supportIconCircleAlpha) * t,
    );
  }
}

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Edge insets shortcuts
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal padding
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

// =============================================================================
// TEXT STYLE EXTENSIONS
// =============================================================================

/// Extension to add text style utilities to BuildContext
/// Access via context.textStyles
extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Helper methods for common text style modifications
extension TextStyleExtensions on TextStyle {
  /// Make text bold
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);

  /// Make text semi-bold
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);

  /// Make text medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Make text normal weight
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);

  /// Make text light
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);

  /// Add custom color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Add custom size
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

// =============================================================================
// COLORS
// =============================================================================

/// Modern, neutral color palette for light mode
/// Uses soft grays and blues instead of purple for a contemporary look
class LightModeColors {
  // Primary: Soft blue-gray for a modern, professional look
  static const lightPrimary = Color(0xFF5B7C99);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFFD8E6F3);
  static const lightOnPrimaryContainer = Color(0xFF1A3A52);

  // Secondary: Complementary gray-blue
  static const lightSecondary = Color(0xFF5C6B7A);
  static const lightOnSecondary = Color(0xFFFFFFFF);

  // Tertiary: Subtle accent color
  static const lightTertiary = Color(0xFF6B7C8C);
  static const lightOnTertiary = Color(0xFFFFFFFF);

  // Error colors
  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  // Surface and background: High contrast for readability
  static const lightSurface = Color(0xFFFBFCFD);
  static const lightOnSurface = Color(0xFF1A1C1E);
  static const lightBackground = Color(0xFFF7F9FA);
  static const lightSurfaceVariant = Color(0xFFE2E8F0);
  static const lightOnSurfaceVariant = Color(0xFF44474E);

  // Outline and shadow
  static const lightOutline = Color(0xFF74777F);
  static const lightShadow = Color(0xFF000000);
  static const lightInversePrimary = Color(0xFFACC7E3);
}

/// Dark mode colors with good contrast
class DarkModeColors {
  // Primary: Lighter blue for dark background
  static const darkPrimary = Color(0xFFACC7E3);
  static const darkOnPrimary = Color(0xFF1A3A52);
  static const darkPrimaryContainer = Color(0xFF3D5A73);
  static const darkOnPrimaryContainer = Color(0xFFD8E6F3);

  // Secondary
  static const darkSecondary = Color(0xFFBCC7D6);
  static const darkOnSecondary = Color(0xFF2E3842);

  // Tertiary
  static const darkTertiary = Color(0xFFB8C8D8);
  static const darkOnTertiary = Color(0xFF344451);

  // Error colors
  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);

  // Surface and background: True dark mode
  static const darkSurface = Color(0xFF1A1C1E);
  static const darkOnSurface = Color(0xFFE2E8F0);
  static const darkSurfaceVariant = Color(0xFF44474E);
  static const darkOnSurfaceVariant = Color(0xFFC4C7CF);

  // Outline and shadow
  static const darkOutline = Color(0xFF8E9099);
  static const darkShadow = Color(0xFF000000);
  static const darkInversePrimary = Color(0xFF5B7C99);
}

/// Font size constants
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 16.0;
  static const double titleSmall = 14.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

// =============================================================================
// THEMES
// =============================================================================

/// Light theme with modern, neutral aesthetic
ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: LightModeColors.lightPrimary,
    onPrimary: LightModeColors.lightOnPrimary,
    primaryContainer: LightModeColors.lightPrimaryContainer,
    onPrimaryContainer: LightModeColors.lightOnPrimaryContainer,
    secondary: LightModeColors.lightSecondary,
    onSecondary: LightModeColors.lightOnSecondary,
    tertiary: LightModeColors.lightTertiary,
    onTertiary: LightModeColors.lightOnTertiary,
    error: LightModeColors.lightError,
    onError: LightModeColors.lightOnError,
    errorContainer: LightModeColors.lightErrorContainer,
    onErrorContainer: LightModeColors.lightOnErrorContainer,
    surface: LightModeColors.lightSurface,
    onSurface: LightModeColors.lightOnSurface,
    surfaceContainerHighest: LightModeColors.lightSurfaceVariant,
    onSurfaceVariant: LightModeColors.lightOnSurfaceVariant,
    outline: LightModeColors.lightOutline,
    shadow: LightModeColors.lightShadow,
    inversePrimary: LightModeColors.lightInversePrimary,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: LightModeColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: LightModeColors.lightOnSurface,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: LightModeColors.lightOutline.withOpacity(0.2),
        width: 1,
      ),
    ),
  ),
  textTheme: _buildTextTheme(Brightness.light),
);

/// Dark theme with gamer aesthetic - neon accents on dark backgrounds
ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: GamerColors.accent,
    onPrimary: GamerColors.darkBackground,
    primaryContainer: GamerColors.darkCard,
    onPrimaryContainer: GamerColors.accent,
    secondary: GamerColors.accentSecondary,
    onSecondary: GamerColors.darkBackground,
    tertiary: GamerColors.success,
    onTertiary: GamerColors.darkBackground,
    error: GamerColors.danger,
    onError: GamerColors.darkBackground,
    surface: GamerColors.darkSurface,
    onSurface: GamerColors.textPrimary,
    surfaceContainerHighest: GamerColors.darkCard,
    onSurfaceVariant: GamerColors.textSecondary,
    outline: GamerColors.textTertiary,
    shadow: Colors.black,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: GamerColors.darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: GamerColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: CardThemeData(
    color: GamerColors.darkCard,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: GamerColors.textTertiary.withValues(alpha: 0.22),
        width: 1,
      ),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: GamerColors.accent,
      foregroundColor: GamerColors.darkBackground,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: GamerColors.accent,
      textStyle: GoogleFonts.rajdhani(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textTheme: _buildGamerTextTheme(),
);

TextTheme _buildGamerTextTheme() {
  return TextTheme(
    displayLarge: GoogleFonts.orbitron(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: GamerColors.textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.orbitron(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: GamerColors.textPrimary,
    ),
    displaySmall: GoogleFonts.orbitron(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: GamerColors.textPrimary,
    ),
    headlineLarge: GoogleFonts.orbitron(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: GamerColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.orbitron(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: GamerColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.orbitron(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: GamerColors.textPrimary,
    ),
    titleLarge: GoogleFonts.rajdhani(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: GamerColors.textPrimary,
    ),
    titleMedium: GoogleFonts.rajdhani(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: GamerColors.textPrimary,
    ),
    titleSmall: GoogleFonts.rajdhani(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: GamerColors.textSecondary,
    ),
    labelLarge: GoogleFonts.rajdhani(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: GamerColors.textPrimary,
    ),
    labelMedium: GoogleFonts.rajdhani(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: GamerColors.textSecondary,
    ),
    labelSmall: GoogleFonts.rajdhani(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: GamerColors.textTertiary,
    ),
    bodyLarge: GoogleFonts.rajdhani(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: GamerColors.textPrimary,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.rajdhani(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: GamerColors.textSecondary,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.rajdhani(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: GamerColors.textTertiary,
      height: 1.4,
    ),
  );
}

TextTheme _buildTextTheme(Brightness brightness) {
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: FontSizes.displayLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: FontSizes.displayMedium,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: FontSizes.displaySmall,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: FontSizes.headlineLarge,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: FontSizes.headlineMedium,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: FontSizes.headlineSmall,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: FontSizes.titleLarge,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: FontSizes.titleMedium,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: FontSizes.titleSmall,
      fontWeight: FontWeight.w500,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: FontSizes.labelLarge,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: FontSizes.labelMedium,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: FontSizes.labelSmall,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: FontSizes.bodyLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: FontSizes.bodyMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: FontSizes.bodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
  );
}
