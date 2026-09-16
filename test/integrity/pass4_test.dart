import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:level_up_your_faith/theme/scripture_theme.dart';
import 'package:level_up_your_faith/widgets/bible_reader_styles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await (await StorageService.getInstance()).clear();
  });
  test('appearance persists independently without changing saved user records',
      () async {
    final storage = await StorageService.getInstance();
    await storage.save('progress-sentinel', '{"xp":1234,"journey":"saved"}');
    final s = SettingsProvider();
    await s.initialize();
    await s.setBibleReaderTheme('sepia');
    final priorSettings = storage.getString('app_settings_v1');
    await s.setQuestTheme(ScriptureThemes.scriptureDark);
    expect(s.bibleReaderTheme, 'night');
    expect(storage.getString('app_settings_v1'), priorSettings);
    final restored = SettingsProvider();
    await restored.initialize();
    expect(restored.questThemeId, ScriptureThemes.scriptureDark);
    expect(restored.readerFollowsTheme, isTrue);
    await restored.setReaderFollowsTheme(false);
    expect(restored.bibleReaderTheme, 'sepia');
    await restored.setBibleReaderTheme('paper');
    expect(restored.questThemeId, ScriptureThemes.scriptureDark);
    expect(restored.bibleReaderTheme, 'paper');
    await restored.setQuestTheme(ScriptureThemes.scriptureLight);
    await restored.setQuestTheme(ScriptureThemes.scriptureDark);
    expect(restored.bibleReaderTheme, 'paper',
        reason:
            'a deliberate reader override survives future app-theme changes');
    expect(storage.getString('progress-sentinel'),
        '{"xp":1234,"journey":"saved"}');
    s.dispose();
    restored.dispose();
  });
  test('legacy night and sepia reader settings survive first load', () async {
    final storage = await StorageService.getInstance();
    for (final reader in ['night', 'sepia']) {
      await storage.save(
          'app_settings_v1', jsonEncode({'bibleReaderTheme': reader}));
      final s = SettingsProvider();
      await s.initialize();
      expect(s.bibleReaderTheme, reader);
      expect(s.readerFollowsTheme, isFalse);
      expect(
          s.questThemeId,
          reader == 'night'
              ? ScriptureThemes.scriptureDark
              : ScriptureThemes.scriptureLight);
      expect(storage.getString('scripture_appearance_v1'), isNull);
      s.dispose();
    }
  });
  test(
      'unreadable appearance is not overwritten on load, invalid selection rejected',
      () async {
    final storage = await StorageService.getInstance();
    await storage.save('scripture_appearance_v1', '{broken');
    final s = SettingsProvider();
    await s.initialize();
    expect(storage.getString('scripture_appearance_v1'), '{broken');
    await expectLater(s.setQuestTheme('missing'), throwsArgumentError);
    expect(storage.getString('scripture_appearance_v1'), '{broken');
    s.dispose();
  });
  test('both palettes keep body, secondary, gold and reader text legible', () {
    double contrast(a, b) {
      final x = a.computeLuminance() as double,
          y = b.computeLuminance() as double;
      return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
    }

    for (final night in [false, true]) {
      final p = QuestPalette(night: night);
      for (final surface in [p.darkBackground, p.darkCard, p.darkSurface]) {
        for (final ink in [p.textPrimary, p.textSecondary, p.gold, p.accent]) {
          expect(contrast(ink, surface), greaterThanOrEqualTo(4.5));
        }
      }
      final reader = BibleReaderStyles.themeFor(night ? 'night' : 'paper');
      expect(contrast(reader.text, reader.background), greaterThanOrEqualTo(7));
      expect(
          contrast(reader.red, reader.background), greaterThanOrEqualTo(4.5));
    }
  });
}
