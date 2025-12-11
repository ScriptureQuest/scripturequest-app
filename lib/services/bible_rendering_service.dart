import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/widgets/bible_reader_styles.dart';
import 'package:level_up_your_faith/models/settings.dart';
import 'package:level_up_your_faith/utils/bible_red_letter_helper.dart';
import 'package:level_up_your_faith/services/bible_service.dart';

/// Global renderer for Bible text that applies red-letter rules across the app.
class BibleRenderingService {
  const BibleRenderingService._();

  /// Build a TextSpan for a single verse, applying red-letter style if applicable
  /// and if enabled in settings. Expects a canonical verse reference like
  /// "John 3:16" (case-insensitive book allowed). If parsing fails, falls back
  /// to normal body style.
  static TextSpan buildVerseSpan(
    BuildContext context, {
    required String reference,
    required String text,
  }) {
    final sp = context.read<SettingsProvider?>();
    final showRed = sp?.redLettersEnabled ?? true;
    final fontScale = sp?.bibleFontScale ?? 1.0;
    final themeKey = sp?.bibleReaderTheme ?? 'paper';
    final themeData = BibleReaderStyles.themeFor(themeKey);
    final fontStyle = sp?.readerFontStyle ?? ReaderFontStyle.classicSerif;

    bool isJesus = false;
    if (showRed) {
      try {
        final parsed = BibleService.instance.parseReference(reference);
        final String? book = parsed['bookDisplay'] as String?;
        final int? chapter = parsed['chapter'] as int?;
        // Extract verse number from reference
        final m = RegExp(r':(\d+)').firstMatch(reference);
        final int? verseNum = m != null ? int.tryParse(m.group(1)!) : null;
        if (book != null && chapter != null && verseNum != null) {
          isJesus = BibleRedLetterHelper.isJesusSpeaking(bookName: book, chapter: chapter, verseNumber: verseNum);
        }
      } catch (_) {}
    }

    return TextSpan(
      text: text,
      style: isJesus
          ? BibleReaderStyles.jesusWords(fontScale, themeData, fontStyle: fontStyle)
          : BibleReaderStyles.verseBody(fontScale, themeData, fontStyle: fontStyle),
    );
  }

  /// Convenience widget to render verse text with correct style.
  static Widget richText(
    BuildContext context, {
    required String reference,
    required String text,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final span = buildVerseSpan(context, reference: reference, text: text);
    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.visible,
      text: span,
    );
  }
}
