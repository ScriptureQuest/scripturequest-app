import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

/// Presentation scope only: the rest of the application retains its own theme.
class ReadingDesign extends StatelessWidget {
  final Widget child;
  const ReadingDesign({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final preference = context.watch<SettingsProvider>().bibleReaderTheme;
    final night = preference == 'night';
    final paper = preference == 'sepia'
        ? const Color(0xFFF3E8D3)
        : const Color(0xFFF7F5EE);
    final background = night ? const Color(0xFF131722) : paper;
    final ink = night ? const Color(0xFFE5E7EB) : const Color(0xFF203C38);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF23675B),
      brightness: night ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: night ? const Color(0xFF93CDBB) : const Color(0xFF23675B),
      onPrimary: night ? const Color(0xFF123C32) : Colors.white,
      surface: background,
      onSurface: ink,
      surfaceContainerHighest:
          night ? const Color(0xFF202D30) : const Color(0xFFEAEDE5),
      onSurfaceVariant:
          night ? const Color(0xFFBCCBC5) : const Color(0xFF52645F),
      outlineVariant: night ? const Color(0xFF394742) : const Color(0xFFD7DDD4),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = GoogleFonts.interTextTheme(
      base.textTheme,
    ).apply(bodyColor: ink, displayColor: ink);
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: background,
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
        dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      ),
      child: child,
    );
  }
}

class ReadingSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const ReadingSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: child,
      );
}
