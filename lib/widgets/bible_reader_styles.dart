import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:level_up_your_faith/models/settings.dart';

// Simple theme data for the Bible reader area
class BibleReaderThemeData {
  final Color background;
  final Color text;
  final Color muted;
  final Color red;
  final Color accent; // New: theme accent for verse numbers and highlights

  const BibleReaderThemeData({
    required this.background,
    required this.text,
    required this.muted,
    required this.red,
    required this.accent,
  });
}

class BibleReaderStyles {
  // Keep legacy constants for backward compatibility in parts of the app
  // Updated to match the new default "paper" palette
  static const Color paperBackground = Color(0xFFF7F5EE);
  static const Color paperTextColor = Color(0xFF111827);

  // Soft gamer red base for Jesus' words
  static const Color _softNeonRedBase = Color(0xFFE54B4B);

  // Theme resolver
  static BibleReaderThemeData themeFor(String key) {
    switch (key) {
      case 'sepia':
        return const BibleReaderThemeData(
          background: Color(0xFFF3E8D3),
          text: Color(0xFF3B2F2A),
          muted: Color(0xFF7B6658),
          red: Color(0xFFB34141), // warm deep red
          accent: Color(0xFF9E7755), // deeper gold-brown for better contrast
        );
      case 'night':
        return const BibleReaderThemeData(
          background: Color(0xFF131722),
          text: Color(0xFFE5E7EB),
          muted: Color(0xFF9CA3AF),
          red: Color(0xFFFF6A6A), // soft, not neon-bright
          accent: Color(0xFF38BDF8), // soft neon blue
        );
      case 'paper':
      default:
        return const BibleReaderThemeData(
          background: Color(0xFFF7F5EE),
          text: Color(0xFF111827),
          muted: Color(0xFF6B7280),
          red: Color(0xFFC1121F), // classic red
          accent: Color(0xFF0EA5E9), // FaithQuest teal accent
        );
    }
  }

  // New themed styles
  static TextStyle verseNumber(double fontScale, BibleReaderThemeData t, {ReaderFontStyle fontStyle = ReaderFontStyle.classicSerif}) {
    final baseStyle = TextStyle(
      fontSize: 12.5 * fontScale,
      fontWeight: FontWeight.w700,
      color: t.accent.withValues(alpha: 0.95), // POPS but not neon-bright
      height: 1.4,
    );
    return fontStyle == ReaderFontStyle.classicSerif
        ? GoogleFonts.lora(textStyle: baseStyle)
        : GoogleFonts.inter(textStyle: baseStyle);
  }

  static TextStyle verseBody(double fontScale, BibleReaderThemeData t, {ReaderFontStyle fontStyle = ReaderFontStyle.classicSerif}) {
    final baseStyle = TextStyle(
      fontSize: 14 * fontScale,
      height: 1.6,
      color: t.text,
    );
    return fontStyle == ReaderFontStyle.classicSerif
        ? GoogleFonts.lora(textStyle: baseStyle)
        : GoogleFonts.inter(textStyle: baseStyle);
  }

  static TextStyle jesusWords(double fontScale, BibleReaderThemeData t, {ReaderFontStyle fontStyle = ReaderFontStyle.classicSerif}) {
    final baseStyle = TextStyle(
      fontSize: 14 * fontScale,
      height: 1.6,
      color: t.red,
      fontWeight: FontWeight.w500,
    );
    return fontStyle == ReaderFontStyle.classicSerif
        ? GoogleFonts.lora(textStyle: baseStyle)
        : GoogleFonts.inter(textStyle: baseStyle);
  }

  static TextStyle verseText(double f, BibleReaderThemeData t) {
    return verseBody(f, t);
  }

  static BoxDecoration paperBackgroundDecoration(BibleReaderThemeData t) {
    return BoxDecoration(
      color: t.background,
      borderRadius: BorderRadius.circular(12),
    );
  }

  // Backward-compatible wrappers (default to "paper" theme)
  static TextStyle verseTextLegacy(double fontScale, {ReaderFontStyle fontStyle = ReaderFontStyle.classicSerif}) => verseBody(fontScale, themeFor('paper'), fontStyle: fontStyle);

  static TextStyle headingText(double fontScale) {
    return TextStyle(
      fontSize: 18.0 * fontScale,
      fontWeight: FontWeight.w600,
      color: paperTextColor,
    );
  }

  static TextStyle verseNumberLegacy(double fontScale) => verseNumber(fontScale, themeFor('paper'));

  static TextStyle verseBodyLegacy(double fontScale) => verseBody(fontScale, themeFor('paper'));

  static TextStyle jesusWordsLegacy(double fontScale) => jesusWords(fontScale, themeFor('paper'));

  // Legacy helpers preserve existing call sites without theme awareness
  // Highlight color palette (sacred dark friendly): sun/mint/violet
  static Color highlightColor(String colorKey) {
    switch (colorKey) {
      case 'sun':
        // warm amber suitable for dark backgrounds
        return const Color(0xFFFFC857);
      case 'mint':
        // soft green mint
        return const Color(0xFF7ED9B6);
      case 'violet':
        // calm lavender/violet
        return const Color(0xFFB39DDB);
      default:
        // fallback to accent
        return themeFor('night').accent;
    }
  }
}
