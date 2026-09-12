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

    final body =
        BibleReaderStyles.verseBody(fontScale, themeData, fontStyle: fontStyle);
    final parsed = BibleService.instance.parseReference(reference);
    final book = parsed['bookDisplay'] as String?;
    final chapter = parsed['chapter'] as int?;
    final match = RegExp(r':(\d+)$').firstMatch(reference.trim());
    if (book == null || chapter == null || match == null) {
      return TextSpan(text: text, style: body);
    }
    return BibleRedLetterHelper.render(
        bookName: book,
        chapter: chapter,
        verseNumber: int.parse(match[1]!),
        text: text,
        enabled: showRed,
        bodyStyle: body,
        speechStyle: BibleReaderStyles.jesusWords(fontScale, themeData,
            fontStyle: fontStyle));
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
      textScaler: MediaQuery.textScalerOf(context),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.visible,
      text: span,
    );
  }
}
