import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class ScriptureThemes {
  static const scriptureLight = 'scripture-light';
  static const scriptureDark = 'scripture-dark';
  static const ids = [scriptureLight, scriptureDark];
  static String label(String id) =>
      id == scriptureDark ? 'Scripture Dark' : 'Scripture Light';
  static ThemeData build(String id) {
    final night = id == scriptureDark;
    final background =
        night ? const Color(0xFF111C29) : const Color(0xFFF7F5EE);
    final ink = night ? const Color(0xFFE5E7EB) : const Color(0xFF203C38);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF23675B),
      brightness: night ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: night ? const Color(0xFF94CFD0) : const Color(0xFF23675B),
      onPrimary: night ? const Color(0xFF143B41) : Colors.white,
      surface: background,
      onSurface: ink,
      surfaceContainerHighest:
          night ? const Color(0xFF1D3040) : const Color(0xFFEAEDE5),
      onSurfaceVariant:
          night ? const Color(0xFFBCCBC5) : const Color(0xFF52645F),
      outlineVariant: night ? const Color(0xFF394742) : const Color(0xFFD7DDD4),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: ink, displayColor: ink);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      extensions: [QuestPalette(night: night)],
      textTheme: text.copyWith(
        headlineLarge: GoogleFonts.lora(
          fontSize: 32,
          height: 1.2,
          color: ink,
        ),
        headlineMedium: GoogleFonts.lora(
          fontSize: 27,
          height: 1.25,
          color: ink,
        ),
        headlineSmall: GoogleFonts.lora(
          fontSize: 23,
          height: 1.3,
          color: ink,
        ),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.55),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 52),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
          backgroundColor: scheme.surfaceContainerHighest,
          contentTextStyle: text.bodyMedium,
          actionTextColor: scheme.primary),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}

/// Semantic colors shared by modernized pages. Expression belongs to components,
/// so a quiet reader and a celebratory badge can share the same theme identity.
class QuestPalette extends ThemeExtension<QuestPalette> {
  final bool night;
  const QuestPalette({required this.night});
  static QuestPalette of(BuildContext context) =>
      Theme.of(context).extension<QuestPalette>() ??
      QuestPalette(night: Theme.of(context).brightness == Brightness.dark);
  Color get darkBackground =>
      night ? const Color(0xff111c29) : const Color(0xfff7f5ee);
  Color get darkSurface =>
      night ? const Color(0xff172735) : const Color(0xfff0f1e9);
  Color get darkCard =>
      night ? const Color(0xff1d3040) : const Color(0xffeef0e8);
  Color get textPrimary =>
      night ? const Color(0xffe5e7eb) : const Color(0xff203c38);
  Color get textSecondary =>
      night ? const Color(0xffb9ced1) : const Color(0xff52645f);
  Color get textTertiary => textSecondary;
  Color get accent => night ? const Color(0xff94cfd0) : const Color(0xff23675b);
  Color get accentSecondary =>
      night ? const Color(0xffc6b9e2) : const Color(0xff6b548a);
  Color get success =>
      night ? const Color(0xff9dd2b1) : const Color(0xff276849);
  Color get danger => night ? const Color(0xffffa9a3) : const Color(0xffa93334);
  Color get gold => night ? const Color(0xffdfc187) : const Color(0xff886324);
  Color get neonGold => gold;
  Color get neonCyan => accent;
  Color get neonPurple => accentSecondary;
  Color get neonGreen => success;
  Color get neonPink => danger;
  @override
  QuestPalette copyWith({bool? night}) =>
      QuestPalette(night: night ?? this.night);
  @override
  QuestPalette lerp(covariant QuestPalette? other, double t) =>
      t < .5 ? this : other ?? this;
}
