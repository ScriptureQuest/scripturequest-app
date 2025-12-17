import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/providers/settings_provider.dart';
import 'package:level_up_your_faith/models/settings.dart';
import 'package:level_up_your_faith/models/quiz_difficulty.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/models/verse_bookmark.dart';
import 'package:level_up_your_faith/models/bible_version.dart';
import 'package:level_up_your_faith/widgets/bible_reader_styles.dart';
import 'package:level_up_your_faith/utils/bible_red_letter_helper.dart';
import 'package:level_up_your_faith/services/bible_rendering_service.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';
import 'package:level_up_your_faith/widgets/reward_toast.dart';
import 'package:level_up_your_faith/widgets/journal/journal_editor_sheet.dart';
import 'package:level_up_your_faith/services/progress/progress_engine.dart';
import 'package:level_up_your_faith/services/progress/progress_event.dart';
import 'package:level_up_your_faith/services/chapter_quiz_service.dart';

// Haptic feedback types (top-level for class access)
enum _HapticType { selectionClick, lightImpact }

class VersesScreen extends StatefulWidget {
  final String? selectedReference;
  final int? initialFocusVerse; // when provided, scroll to and gently highlight this verse
  const VersesScreen({super.key, this.selectedReference, this.initialFocusVerse});

  @override
  State<VersesScreen> createState() => _VersesScreenState();
}

class _VersesScreenState extends State<VersesScreen> {
  String? _currentReference;
  String _selectedVersionCode = 'KJV';
  String _passageText = '';
  bool _loading = false;
  bool _initialized = false;
  String? _selectedBook; // Display name as provided by BibleService
  int? _selectedChapter;
  bool _isChapterView = false; // true when browsing via dropdowns

  // PageView-based chapter navigation state
  PageController? _pageController;
  int _pageCountForBook = 0; // number of chapters for current book
  bool _suppressPageEvents = false; // avoid loops when jumping programmatically
  final Map<String, Map<int, String>> _chapterCache = {}; // book -> chapter -> text

  // Reading time tracking for quest completion (daily + weekly)
  DateTime? _readingStartTime;
  bool _dailyQuestProgressedThisSession = false;
  bool _hasMetReadingThreshold = false; // Set to true when user has read for minimum time
  static const int _minimumReadingSecondsForQuest = 45; // Minimum time to gate quest progression

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // Initialize local state from provider/user on first build
        _selectedVersionCode = provider.preferredBibleVersionCode;
        _currentReference ??= (widget.selectedReference ?? '').trim().isNotEmpty
            ? widget.selectedReference!.trim()
            : _currentReference;

        // Reader theme + font scale
        final settings = context.watch<SettingsProvider>();
        final double fontScale = settings.bibleFontScale;
        final themeData = BibleReaderStyles.themeFor(settings.bibleReaderTheme);

        return Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                    onPressed: () => context.pop(),
                    tooltip: 'Back',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    padding: const EdgeInsets.all(6),
                  )
                : null,
            title: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                final book = _selectedBook;
                if (book != null && book.isNotEmpty) {
                  _openChapterPickerForBook(book);
                } else {
                  _openJumpToBookSheet();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: GamerColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: GamerColors.accent.withValues(alpha: 0.45), width: 1),
                ),
                child: Builder(builder: (context) {
                  final book = _selectedBook;
                  final ch = _selectedChapter;
                  final label = (book == null || book.isEmpty || ch == null)
                      ? 'Bible'
                      : '${book} · ${ch}';
                  return Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: GamerColors.textPrimary,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w600,
                        ),
                  );
                }),
              ),
            ),
            centerTitle: true,
            actions: [
              // Refresh button (web-friendly alternative to pull-to-refresh)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh chapter',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: const EdgeInsets.all(6),
                onPressed: _refreshChapterContent,
              ),
              // Single entry point: Bible Menu
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Bible menu',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: const EdgeInsets.all(6),
                onPressed: _openBibleMenu,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: _buildChapterPager(
                    fontScale: fontScale,
                    themeData: themeData,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Restored: Version selector sheet (always available, even with a single version)
  Future<void> _openVersionSelectorSheet() async {
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, color: GamerColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select Bible Version',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                _buildVersionSelector(),
              ],
            ),
          ),
        );
      },
    );
    RewardToast.setBottomSheetOpen(false);
  }

  // Wrapper to match expected handler name in requirements
  Future<void> _openBibleMenu() => _openBibleMenuSheet();

  // Reader Settings bottom sheet: Font + Text size (reuses existing components/logic)
  Future<void> _openReaderSettings() async {
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final settings = context.watch<SettingsProvider>();
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_size, color: GamerColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Reader Settings', style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Section: Font
                Text(
                  'Font',
                  style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                ),
                const SizedBox(height: 8),
                _FontStyleChips(
                  current: settings.readerFontStyle,
                  onChanged: (f) async {
                    await context.read<SettingsProvider>().setReaderFontStyle(f);
                  },
                ),

                const SizedBox(height: 12),

                // Section: Text size
                Text(
                  'Text size',
                  style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                ),
                const SizedBox(height: 8),
                _TextSizeSlider(
                  value: settings.bibleFontScale,
                  onChanged: (v) {
                    context.read<SettingsProvider>().setBibleFontScale(v);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    RewardToast.setBottomSheetOpen(false);
  }

  // Appearance bottom sheet: Reader color scheme (reuses existing chips/logic)
  Future<void> _openAppearanceSheet() async {
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final settings = context.watch<SettingsProvider>();
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.color_lens_outlined, color: GamerColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Appearance', style: theme.textTheme.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Reading style',
                  style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                ),
                const SizedBox(height: 8),
                _ReaderStyleChips(
                  current: settings.readerColorScheme,
                  onChanged: (s) async {
                    await context.read<SettingsProvider>().setReaderColorScheme(s);
                  },
                ),
                const SizedBox(height: 12),

                // Toggle: Red letters for Jesus' words
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "Show Jesus’ words in red",
                    style: theme.textTheme.labelMedium,
                  ),
                  activeColor: GamerColors.accent,
                  value: settings.redLettersEnabled,
                  onChanged: (val) async {
                    await context.read<SettingsProvider>().setRedLettersEnabled(val);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    RewardToast.setBottomSheetOpen(false);
  }

  @override
  void initState() {
    super.initState();
    _currentReference = (widget.selectedReference ?? '').trim().isNotEmpty ? widget.selectedReference!.trim() : null;
  }

  // Deprecated: per-verse reader settings sheet (moved into Bible Menu)

  // Opens the unified Bible Menu bottom sheet (single entry point for all controls)
  Future<void> _openBibleMenuSheet() async {
    // Haptic feedback on open (no-op on web)
    _triggerHaptic(_HapticType.selectionClick);
    
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      backgroundColor: GamerColors.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final app = ctx.watch<AppProvider>();
        final settings = ctx.watch<SettingsProvider>();
        
        // Parse last reading for display and navigation
        final lastKey = app.lastReadingKey;
        String? lastSubtitle;
        String? lastNavRef;
        if (lastKey != null && lastKey.trim().isNotEmpty) {
          final parts = lastKey.split(':');
          if (parts.length >= 2) {
            final book = parts[0].trim();
            final chapter = int.tryParse(parts[1]) ?? 0;
            if (book.isNotEmpty && chapter > 0) {
              lastSubtitle = '$book $chapter';
              lastNavRef = Uri.encodeComponent('$book $chapter');
            }
          }
        }
        
        // Check quiz availability for current chapter (use display name, not ref)
        final book = _selectedBook;
        final chapter = _selectedChapter;
        final bool quizAvailable = (book != null && chapter != null) &&
            ChapterQuizService.getQuizForChapter(book, chapter) != null;
        
        final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
        
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bible Menu', style: theme.textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // === READER PREFERENCES (inline) ===
                    Text(
                      'Reader Preferences',
                      style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    
                    // Reading style (Paper / Sepia / Night)
                    Text('Reading style', style: theme.textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary.withValues(alpha: 0.7))),
                    const SizedBox(height: 6),
                    _ReaderStyleChips(
                      current: settings.readerColorScheme,
                      onChanged: (s) async {
                        _triggerHaptic(_HapticType.selectionClick);
                        await ctx.read<SettingsProvider>().setReaderColorScheme(s);
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // Red letters toggle
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        "Show Jesus' words in red",
                        style: theme.textTheme.bodyMedium,
                      ),
                      activeColor: GamerColors.accent,
                      value: settings.redLettersEnabled,
                      onChanged: (val) async {
                        _triggerHaptic(_HapticType.selectionClick);
                        await ctx.read<SettingsProvider>().setRedLettersEnabled(val);
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // Font style (Classic / Clean)
                    Text('Font', style: theme.textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary.withValues(alpha: 0.7))),
                    const SizedBox(height: 6),
                    _FontStyleChips(
                      current: settings.readerFontStyle,
                      onChanged: (f) async {
                        _triggerHaptic(_HapticType.selectionClick);
                        await ctx.read<SettingsProvider>().setReaderFontStyle(f);
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // Text size slider
                    Row(
                      children: [
                        Expanded(
                          child: Text('Text size', style: theme.textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary.withValues(alpha: 0.7))),
                        ),
                        Text(
                          '${(settings.bibleFontScale * 100).round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(color: GamerColors.accent),
                        ),
                      ],
                    ),
                    _TextSizeSlider(
                      value: settings.bibleFontScale,
                      onChanged: (v) {
                        ctx.read<SettingsProvider>().setBibleFontScale(v);
                      },
                    ),

                    const Divider(height: 24),

                    // === NAVIGATION ===
                    Text(
                      'Navigation',
                      style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _menuTile(
                      ctx,
                      icon: Icons.menu_book,
                      title: 'Jump to Book & Chapter',
                      subtitle: 'Choose any book, then a chapter',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _openJumpToBookSheet();
                      },
                    ),
                    _menuTile(
                      ctx,
                      icon: Icons.history,
                      title: 'Return to Last Reading',
                      subtitle: lastSubtitle,
                      enabled: lastNavRef != null,
                      onTap: lastNavRef == null
                          ? null
                          : () {
                              Navigator.of(ctx).pop();
                              context.push('/verses?ref=$lastNavRef');
                            },
                    ),

                    const Divider(height: 24),

                    // === YOUR NOTES & MARKS ===
                    Text(
                      'Your Notes & Marks',
                      style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _menuTile(
                      ctx,
                      icon: Icons.brush,
                      title: 'Highlights',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.push('/highlights');
                      },
                    ),
                    _menuTile(
                      ctx,
                      icon: Icons.bookmark,
                      title: 'Bookmarks',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.push('/bookmarks');
                      },
                    ),
                    _menuTile(
                      ctx,
                      icon: Icons.favorite,
                      iconColor: GamerColors.neonPurple,
                      title: 'Favorites',
                      onTap: () {
                        Navigator.of(ctx).pop();
                        context.push('/favorite-verses');
                      },
                    ),

                    const Divider(height: 24),

                    // === CHAPTER QUIZ (visibility based on availability) ===
                    Text(
                      'Chapter Quiz',
                      style: theme.textTheme.labelLarge?.copyWith(color: GamerColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    _menuTile(
                      ctx,
                      icon: Icons.quiz_outlined,
                      title: quizAvailable ? 'Chapter Quiz' : 'Chapter Quiz (Coming soon)',
                      subtitle: quizAvailable ? 'Test your understanding of this chapter' : null,
                      enabled: quizAvailable,
                      onTap: quizAvailable
                          ? () {
                              Navigator.of(ctx).pop();
                              if (book != null && chapter != null) {
                                final uri = Uri(path: '/chapter-quiz', queryParameters: {
                                  'book': book,
                                  'chapter': '$chapter',
                                });
                                try {
                                  final bookRef = ctx.read<AppProvider>().bibleService.displayToRef(book);
                                  final diff = ctx.read<SettingsProvider>().preferredQuizDifficulty;
                                  ProgressEngine.instance.emit(
                                    ProgressEvent.chapterQuizStarted(bookRef, chapter, diff.code),
                                  );
                                } catch (_) {}
                                context.push(uri.toString());
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    RewardToast.setBottomSheetOpen(false);
  }
  
  // Safe haptic trigger (no-op on web)
  void _triggerHaptic(_HapticType type) {
    try {
      switch (type) {
        case _HapticType.selectionClick:
          HapticFeedback.selectionClick();
          break;
        case _HapticType.lightImpact:
          HapticFeedback.lightImpact();
          break;
      }
    } catch (_) {
      // Gracefully no-op on platforms that don't support haptics
    }
  }
  
  // Refresh current chapter content (safe - doesn't reset preferences)
  void _refreshChapterContent() {
    final book = _selectedBook;
    final chapter = _selectedChapter;
    if (book != null && chapter != null) {
      // Clear cached chapter to force reload
      _chapterCache[book]?.remove(chapter);
      if (kDebugMode) {
        debugPrint('[BibleRefresh] clearing cache for $book $chapter');
      }
      setState(() {});
    }
  }

  // Bottom sheet to jump quickly to any book, then to a chapter (two-step)
  Future<void> _openJumpToBookSheet() async {
    final app = context.read<AppProvider>();
    final books = app.bibleService.getAllBooks();
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // Partition books into OT and NT based on the index of Matthew
        final matthewIndex = books.indexWhere((b) => b.toLowerCase() == 'matthew');
        final ot = matthewIndex > 0 ? books.sublist(0, matthewIndex) : books;
        final nt = matthewIndex > 0 ? books.sublist(matthewIndex) : <String>[];
        int selectedTab = (_selectedBook != null && (_selectedBook ?? '').isNotEmpty)
            ? ((ot.contains(_selectedBook)) ? 0 : 1)
            : 1; // default NT (common start) if unknown

        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              final showList = selectedTab == 0 ? ot : nt;
              final maxSheetHeight = MediaQuery.of(ctx).size.height * 0.80;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book, color: GamerColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Jump to Book', style: Theme.of(context).textTheme.titleLarge),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Segmented control: OT / NT
                    Container(
                      decoration: BoxDecoration(
                        color: GamerColors.darkSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25)),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          _segButton(
                            label: 'Old Testament',
                            selected: selectedTab == 0,
                            onTap: () => setSheetState(() => selectedTab = 0),
                          ),
                          _segButton(
                            label: 'New Testament',
                            selected: selectedTab == 1,
                            onTap: () => setSheetState(() => selectedTab = 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxSheetHeight),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 3.3,
                        ),
                        itemCount: showList.length,
                        itemBuilder: (context, index) {
                          final b = showList[index];
                          final isCurrent = b == _selectedBook;
                          return _BookChip(
                            label: b,
                            selected: isCurrent,
                            onTap: () {
                              Navigator.of(ctx).pop();
                              final uri = Uri(path: '/verses', queryParameters: {
                                'ref': '$b 1',
                              });
                              if (mounted) context.push(uri.toString());
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    RewardToast.setBottomSheetOpen(false);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  /// Start or restart the reading timer when a chapter is loaded
  void _startReadingTimer() {
    if (_readingStartTime == null) {
      _readingStartTime = DateTime.now();
      debugPrint('Reading timer started');
    }
  }

  /// Check if the user has met the reading time threshold for quest progression.
  /// This sets a flag but does NOT progress any quest automatically.
  void _updateReadingTimeThreshold() {
    try {
      if (_hasMetReadingThreshold) return; // Already met
      if (_readingStartTime == null) return;
      
      final duration = DateTime.now().difference(_readingStartTime!);
      if (duration.inSeconds >= _minimumReadingSecondsForQuest) {
        _hasMetReadingThreshold = true;
        debugPrint('Reading time threshold met: ${duration.inSeconds}s');
      }
    } catch (e) {
      debugPrint('_updateReadingTimeThreshold error: $e');
    }
  }

  /// Progress the daily reading quest if BOTH conditions are met:
  /// 1) User has spent minimum reading time (_hasMetReadingThreshold)
  /// 2) User explicitly completed the chapter (by calling this method)
  void _progressDailyQuestIfEligible(AppProvider provider) {
    try {
      if (_dailyQuestProgressedThisSession) return; // Already progressed
      
      // Update threshold status before checking
      _updateReadingTimeThreshold();
      
      if (_hasMetReadingThreshold) {
        _dailyQuestProgressedThisSession = true;
        // Pass current book and chapter for proper quest target matching
        provider.progressDailyReadingQuest(
          book: _selectedBook,
          chapter: _selectedChapter,
        );
        debugPrint('Daily reading quest progressed via chapter completion: $_selectedBook $_selectedChapter');
      } else {
        final elapsed = _readingStartTime != null 
            ? DateTime.now().difference(_readingStartTime!).inSeconds 
            : 0;
        debugPrint('Daily quest NOT progressed: reading time ${elapsed}s < ${_minimumReadingSecondsForQuest}s threshold');
      }
    } catch (e) {
      debugPrint('_progressDailyQuestIfEligible error: $e');
    }
  }

  // Removed: in-body Return to Last Reading card. This functionality now lives in the Bible Menu.

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final provider = Provider.of<AppProvider?>(context, listen: false);
    if (provider == null) return;

    // Determine initial selection: deep link, last selection, last reference, or default
    final hasIncoming = (_currentReference ?? '').trim().isNotEmpty;
    if (hasIncoming) {
      _applyParsedReference(provider, _currentReference!);
    } else if ((provider.lastBibleBook ?? '').isNotEmpty && (provider.lastBibleChapter ?? 0) > 0) {
      _selectedBook = provider.lastBibleBook;
      _selectedChapter = provider.lastBibleChapter;
      if (_selectedBook != null && _selectedChapter != null) {
        _setupPagerForBook(provider, book: _selectedBook!, initialChapter: _selectedChapter!, jump: true);
      }
    } else {
      final lastRef = (provider.lastBibleReference ?? '').trim();
      if (lastRef.isNotEmpty) {
        _applyParsedReference(provider, lastRef);
      } else {
        // Default to John 3
        _selectedBook = 'John';
        _selectedChapter = 3;
        _setupPagerForBook(provider, book: _selectedBook!, initialChapter: _selectedChapter!, jump: true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant VersesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newRef = (widget.selectedReference ?? '').trim();
    if (newRef.isNotEmpty && newRef != (_currentReference ?? '')) {
      final provider = Provider.of<AppProvider?>(context, listen: false);
      if (provider != null) {
        _applyParsedReference(provider, newRef);
      }
    }
  }

  Widget _buildPassageArea(AppProvider provider) {
    final fontScale = context.watch<SettingsProvider>().bibleFontScale;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: GamerColors.accent),
            ))
          else if ((_currentReference ?? '').isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Select a book and chapter to begin, or open Scripture from a Quest. ✨',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          else ...[
            Row(
              children: [
                const Icon(Icons.bookmark, color: GamerColors.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_currentReference ?? ''} · ${_selectedVersionCode.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _buildFavoriteToggle(provider),
              ],
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final ref = (_currentReference ?? '').trim();
              final looksSingleVerse = RegExp(r'^.+\s+\d+:\d+$').hasMatch(ref);
              if (looksSingleVerse) {
                return RichText(
                  text: BibleRenderingService.buildVerseSpan(
                    context,
                    reference: ref,
                    text: _passageText,
                  ),
                );
              }
              return Text(
                _passageText,
                style: BibleReaderStyles.verseTextLegacy(
                  fontScale,
                  fontStyle: context.read<SettingsProvider>().readerFontStyle,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildChapterPager({
    required double fontScale,
    required BibleReaderThemeData themeData,
  }) {
    final provider = context.watch<AppProvider>();
    // If nothing is selected yet, prompt the user
    if ((_selectedBook ?? '').isEmpty) {
      return Container(
        decoration: BibleReaderStyles.paperBackgroundDecoration(themeData),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Select a book and chapter to begin, or open Scripture from a Quest. ✨',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    _ensurePagerConfigured(provider);

    final book = _selectedBook!;
    final chapter = _selectedChapter ?? 1;

    return Container(
      decoration: BibleReaderStyles.paperBackgroundDecoration(themeData),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildStreakRow(provider),
          ),
          const Divider(height: 1),
          Expanded(
            child: _pageController == null
                ? const Center(child: CircularProgressIndicator(color: GamerColors.accent))
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _pageCountForBook,
                    onPageChanged: (idx) {
                      final newChapter = idx + 1;
                      _onChapterChanged(provider, newChapter);
                    },
                    itemBuilder: (context, index) {
                      final ch = index + 1;
                      return _ChapterPage(
                        key: ValueKey('${book}_$ch'),
                        book: book,
                        chapter: ch,
                        cache: _chapterCache,
                        loader: (b, c) => provider.loadKjvChapter(b, c),
                        fontScale: fontScale,
                        themeData: themeData,
                        initialFocusVerse: (ch == chapter) ? widget.initialFocusVerse : null,
                        onChapterCompleted: () {
                          // Progress daily quest if reading time threshold was met
                          _progressDailyQuestIfEligible(provider);
                        },
                        hasMetReadingThreshold: () => _hasMetReadingThreshold,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // (Old in-body book/chapter pill header removed; AppBar pill is the single source of truth.)

  // Restored: Chapter picker for a book; supports being opened standalone or stacked over the book sheet.
  // When parentSheetContext is provided, we close both sheets after selecting a chapter.
  Future<void> _openChapterPickerForBook(String bookDisplay, {BuildContext? parentSheetContext}) async {
    final provider = context.read<AppProvider>();
    final total = provider.bibleService.getChapterCount(bookDisplay);
    final theme = Theme.of(context);
    RewardToast.setBottomSheetOpen(true);
    await showModalBottomSheet(
      context: context,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final maxSheetHeight = MediaQuery.of(ctx).size.height * 0.72;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, color: GamerColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chapters in $bookDisplay',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                // Height-limited scroll area for long books (e.g., Psalms)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxSheetHeight),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (int i = 1; i <= total; i++)
                          _ChapterChip(
                            label: '$i',
                            selected: i == (_selectedChapter ?? -1),
                            read: provider.isChapterRead(bookDisplay, i),
                            onTap: () {
                              if (kDebugMode) {
                                debugPrint('[ChaptersSheet] tapped book=$bookDisplay chapter=$i');
                              }
                              // Close this (chapter) sheet
                              Navigator.of(ctx).pop();
                              // Close the parent (book) sheet if provided
                              if (parentSheetContext != null) {
                                Navigator.of(parentSheetContext).pop();
                              }
                              final uri = Uri(path: '/verses', queryParameters: {
                                'ref': '$bookDisplay $i',
                              });
                              if (mounted) context.push(uri.toString());
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    RewardToast.setBottomSheetOpen(false);
  }

  // Premium-feel, consistent Bible Menu tile with tight, clean spacing
  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    String? title,
    String? subtitle,
    bool enabled = true,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final t = (title ?? '').isEmpty ? null : Text(title!, style: theme.textTheme.titleMedium);
    final sub = (subtitle ?? '').isEmpty ? null : Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: GamerColors.textSecondary));
    return ListTile(
      enabled: enabled,
      dense: false,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      minLeadingWidth: 28,
      leading: Icon(icon, color: iconColor ?? GamerColors.accent),
      title: t,
      subtitle: sub,
      onTap: onTap,
    );
  }

  Widget _buildQuizCta(AppProvider provider, String book, int chapter) {
    final show = provider.shouldOfferQuiz(book, chapter);
    if (!show) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: GamerColors.accent.withValues(alpha: 0.12),
                border: Border.all(color: GamerColors.accent.withValues(alpha: 0.35), width: 1),
              ),
              child: const Icon(Icons.self_improvement, color: GamerColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reflect on this chapter', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Builder(builder: (ctx) {
                    final d = ctx.watch<SettingsProvider>().preferredQuizDifficulty;
                    final n = d.desiredQuestionCount;
                    return Text('Take a ${n}-question quiz', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary));
                  }),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                final uri = Uri(path: '/chapter-quiz', queryParameters: {
                  'book': book,
                  'chapter': '$chapter',
                });
                try {
                  final bookRef = context.read<AppProvider>().bibleService.displayToRef(book);
                  final diff = context.read<SettingsProvider>().preferredQuizDifficulty;
                  ProgressEngine.instance.emit(
                    ProgressEvent.chapterQuizStarted(bookRef, chapter, diff.code),
                  );
                } catch (_) {}
                context.push(uri.toString());
              },
              icon: const Icon(Icons.play_arrow, color: GamerColors.darkBackground),
              label: const Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }

  // Streak row under the header
  Widget _buildStreakRow(AppProvider provider) {
    final streak = provider.currentBibleStreak;
    if (streak <= 0) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.local_fire_department, color: GamerColors.danger, size: 18),
        const SizedBox(width: 6),
        Text(
          'Streak: $streak day${streak == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: GamerColors.danger),
        ),
        const SizedBox(width: 10),
        if (provider.hasStreakXpBonus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GamerColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: GamerColors.success.withValues(alpha: 0.5), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: GamerColors.success, size: 14),
                const SizedBox(width: 6),
                Text(
                  'XP Bonus: +10%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: GamerColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Extracted reusable widgets for bottom sheet
  Widget _buildVersionSelector() {
    final provider = context.watch<AppProvider>();
    return Container(
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: GamerColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedVersionCode,
                dropdownColor: GamerColors.darkCard,
                iconEnabledColor: GamerColors.accent,
                items: BibleVersions.all
                    .map((v) => DropdownMenuItem<String>(
                          value: v.code,
                          child: Text('${v.name} (${v.abbr})',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: GamerColors.textPrimary)),
                        ))
                    .toList(),
                onChanged: (val) async {
                  if (val == null) return;
                  setState(() => _selectedVersionCode = val);
                  await provider.setPreferredBibleVersionCode(val);
                  if (_isChapterView) {
                    // Reload the current chapter in the new version
                    if (_selectedBook != null && _selectedChapter != null) {
                      _loadChapter(provider);
                    }
                  } else if ((_currentReference ?? '').isNotEmpty) {
                    // Reload the current passage in the new version
                    _loadPassage(provider);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookChapterSelector() {
    final provider = context.watch<AppProvider>();
    return Container(
      decoration: BoxDecoration(
        color: GamerColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.explore, color: GamerColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBook,
                hint: const Text('Select Book'),
                dropdownColor: GamerColors.darkCard,
                iconEnabledColor: GamerColors.accent,
                items: provider.bibleService
                    .getAllBooks()
                    .map((b) => DropdownMenuItem<String>(
                          value: b,
                          child: Text(b, style: Theme.of(context).textTheme.bodyMedium),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedBook = val;
                    _selectedChapter = 1;
                  });
                  provider.setLastBibleSelection(bookDisplay: val, chapter: 1);
                  _updateSelectionChapterView(provider);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedChapter,
                hint: const Text('Chapter'),
                dropdownColor: GamerColors.darkCard,
                iconEnabledColor: GamerColors.accent,
                items: _buildChapterItems(provider),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedChapter = val);
                  if (_selectedBook != null) {
                    provider.setLastBibleSelection(bookDisplay: _selectedBook!, chapter: val);
                    _updateSelectionChapterView(provider);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildChapterItems(AppProvider provider) {
    final book = _selectedBook;
    if (book == null) return const <DropdownMenuItem<int>>[];
    final count = provider.bibleService.getChapterCount(book);
    return List<DropdownMenuItem<int>>.generate(
      count,
      (i) => DropdownMenuItem<int>(
        value: i + 1,
        child: Row(
          children: [
            if (provider.isChapterRead(book, i + 1))
              const Icon(Icons.check, color: GamerColors.success, size: 16),
            if (provider.isChapterRead(book, i + 1)) const SizedBox(width: 6),
            Text('Ch ${i + 1}', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _updateReferenceFromSelection(AppProvider provider, {bool load = true}) {
    final book = _selectedBook;
    final chapter = _selectedChapter;
    if (book == null || chapter == null) return;
    final refBook = provider.bibleService.displayToRef(book);
    final ref = '$refBook $chapter:1';
    setState(() {
      _currentReference = ref;
    });
    if (load) _loadPassage(provider);
  }

  void _applyParsedReference(AppProvider provider, String reference) {
    _currentReference = reference.trim();
    final parsed = provider.bibleService.parseReference(_currentReference!);
    final bookDisplay = parsed['bookDisplay'] as String?;
    final chapter = parsed['chapter'] as int?;
    if (bookDisplay != null) {
      _selectedBook = bookDisplay;
      int ch = chapter ?? 1;
      final max = provider.bibleService.getChapterCount(bookDisplay);
      if (max > 0 && ch > max) ch = max;
      if (ch < 1) ch = 1;
      _selectedChapter = ch;
    }
    _isChapterView = true; // use chapter pager; optional verse highlight could be added
    if (_selectedBook != null && _selectedChapter != null) {
      _setupPagerForBook(provider, book: _selectedBook!, initialChapter: _selectedChapter!, jump: true);
    }
  }

  Future<void> _loadPassage(AppProvider provider) async {
    final ref = _currentReference ?? '';
    if (ref.isEmpty) return;
    setState(() => _loading = true);
    // KJV-only for now
    final text = await provider.loadKjvPassage(ref);
    if (!mounted) return;
    setState(() {
      _passageText = text;
      _loading = false;
    });
    // Track last-read reference
    provider.setLastBibleReference(ref);

    // Record Bible open and surface any newly unlocked achievements
    final unlocked = await provider.recordBibleOpen(ref);
    if (!mounted) return;
    if (unlocked.isNotEmpty) {
      final a = unlocked.first;
      final xp = a.xpReward;
      RewardToast.showAchievementUnlocked(
        context,
        title: a.title,
        subtitle: xp > 0 ? '+$xp XP' : null,
      );
    }
  }

  void _updateSelectionChapterView(AppProvider provider, {bool load = true}) {
    final book = _selectedBook;
    final chapter = _selectedChapter;
    if (book == null || chapter == null) return;
    setState(() {
      _isChapterView = true;
      _currentReference = '$book $chapter';
    });
    // Configure pager and move to selected chapter
    _setupPagerForBook(provider, book: book, initialChapter: chapter, jump: !load);
    if (load) {
      _onChapterChanged(provider, chapter, persistOnly: true);
    }
  }

  Future<void> _loadChapter(AppProvider provider) async {
    final book = _selectedBook;
    final chapter = _selectedChapter;
    if (book == null || chapter == null) return;
    setState(() => _loading = true);
    // KJV-only for now
    final text = await provider.loadKjvChapter(book, chapter);
    if (!mounted) return;
    setState(() {
      _passageText = text;
      _loading = false;
    });
    // Track last-read selection as a reference like "Book Chapter"
    final refBook = provider.bibleService.displayToRef(book);
    final chapterRef = '$refBook $chapter';
    provider.setLastBibleReference(chapterRef);
    // Record last reading location for chapter view
    try {
      provider.recordLastReading('$book:$chapter');
    } catch (_) {}

    // Record Bible open and surface any newly unlocked achievements
    final unlocked = await provider.recordBibleOpen(chapterRef);
    if (!mounted) return;
    if (unlocked.isNotEmpty) {
      final a = unlocked.first;
      final xp = a.xpReward;
      RewardToast.showAchievementUnlocked(
        context,
        title: a.title,
        subtitle: xp > 0 ? '+$xp XP' : null,
      );
    }
    // REMOVED: Do NOT mark chapter as completed just by loading passage.
    // Completion is only via the "Complete Chapter" action.
  }

  void _ensurePagerConfigured(AppProvider provider) {
    final book = _selectedBook;
    if (book == null || book.isEmpty) return;
    final count = provider.bibleService.getChapterCount(book);
    if (_pageController == null || _pageCountForBook != count) {
      _pageCountForBook = count;
      final initialPage = ((_selectedChapter ?? 1) - 1).clamp(0, (_pageCountForBook - 1).clamp(0, 9999));
      _pageController?.dispose();
      _pageController = PageController(initialPage: initialPage);
    }
  }

  void _setupPagerForBook(AppProvider provider, {required String book, required int initialChapter, bool jump = true}) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = initialChapter;
    });
    _ensurePagerConfigured(provider);
    if (_pageController != null) {
      final target = (initialChapter - 1).clamp(0, (_pageCountForBook - 1).clamp(0, 9999));
      _suppressPageEvents = true;
      if (jump) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _pageController == null) return;
          if (kDebugMode) {
            debugPrint('[BibleNav] navigateTo book=$book chapter=$initialChapter');
          }
          _pageController!.jumpToPage(target);
          _suppressPageEvents = false;
          _onChapterChanged(provider, initialChapter, persistOnly: true);
          // Record last reading location once when chapter becomes visible
          try {
            provider.recordLastReading('$book:$initialChapter');
          } catch (_) {}
          // REMOVED: Do NOT mark chapter as completed just by viewing it.
          // Completion is only via the "Complete Chapter" action.
          // Start tracking reading time for daily quest completion
          _startReadingTimer();
        });
      } else {
        _pageController!
            .animateToPage(target, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
            .whenComplete(() => _suppressPageEvents = false);
      }
    }
  }

  Future<void> _onChapterChanged(AppProvider provider, int newChapter, {bool persistOnly = false}) async {
    if (_suppressPageEvents) return;
    setState(() {
      _selectedChapter = newChapter;
      _currentReference = '${_selectedBook ?? ''} $newChapter';
    });
    provider.setLastBibleSelection(bookDisplay: _selectedBook ?? '', chapter: newChapter);
    final refBook = provider.bibleService.displayToRef(_selectedBook ?? '');
    final chapterRef = '$refBook $newChapter';
    provider.setLastBibleReference(chapterRef);
    // Also capture last reading as a simple key like "Book:Chapter"
    final displayBook = _selectedBook ?? '';
    if (displayBook.isNotEmpty) {
      try {
        provider.recordLastReading('$displayBook:$newChapter');
      } catch (_) {}
    }
    if (persistOnly) return;
    final unlocked = await provider.recordBibleOpen(chapterRef);
    if (!mounted) return;
    if (unlocked.isNotEmpty) {
      final a = unlocked.first;
      final xp = a.xpReward;
      RewardToast.showAchievementUnlocked(
        context,
        title: a.title,
        subtitle: xp > 0 ? '+$xp XP' : null,
      );
    }

    // REMOVED: Do NOT mark chapter as completed just by paging/swiping.
    // Completion is only via the "Complete Chapter" action.
    // Start/continue reading time tracking (user navigated to a new chapter)
    _startReadingTimer();
    if (kDebugMode) {
      debugPrint('[BibleState] current book=${_selectedBook ?? ''} chapter=$newChapter');
    }
  }

  Widget _buildFavoriteToggle(AppProvider provider) {
    final ref = _currentReference ?? '';
    if (ref.isEmpty) return const SizedBox.shrink();
    final isBookmarked = provider.isReferenceBookmarked(ref);
    return IconButton(
      tooltip: isBookmarked ? 'Remove from Favorites' : 'Add to Favorites',
      onPressed: () async {
        if (isBookmarked) {
          // find bookmark by canonical reference
          final key = _canonicalizeReference(provider, ref);
          final match = provider.bookmarks.firstWhere(
            (b) => _canonicalizeReference(provider, b.reference) == key,
            orElse: () => VerseBookmark(
              id: '',
              reference: '',
              book: '',
              chapter: 0,
              translationCode: 'KJV',
              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            ),
          );
          if (match.id.isNotEmpty) {
            await provider.removeBookmark(match.id);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: GamerColors.darkSurface,
                content: Text('Removed from Favorites'),
              ),
            );
          }
        } else {
          final bm = _buildBookmarkForCurrent(provider);
          if (bm != null) {
            await provider.addBookmark(bm);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: GamerColors.darkSurface,
                content: Text('Added to Favorites'),
              ),
            );
          }
        }
        if (mounted) setState(() {});
      },
      icon: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
        color: isBookmarked ? GamerColors.accent : GamerColors.textSecondary,
      ),
    );
  }

  VerseBookmark? _buildBookmarkForCurrent(AppProvider provider) {
    try {
      final ref = (_currentReference ?? '').trim();
      if (ref.isEmpty) return null;
      // Determine book/chapter/verse
      String displayBook = _selectedBook ?? provider.bibleService.refToDisplay(provider.bibleService.parseReference(ref)['bookRef'] as String? ?? '');
      int chapter = _selectedChapter ?? (provider.bibleService.parseReference(ref)['chapter'] as int? ?? 1);
      int? verse;
      final m = RegExp(r':(\d+)').firstMatch(ref);
      if (!_isChapterView && m != null) {
        verse = int.tryParse(m.group(1)!);
      }
      return VerseBookmark(
        id: '',
        reference: _isChapterView ? '$displayBook $chapter' : ref,
        book: displayBook,
        chapter: chapter,
        verse: verse,
        translationCode: 'KJV',
        note: null,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  String _canonicalizeReference(AppProvider provider, String reference) {
    final raw = reference.trim();
    final m = RegExp(r'^(.+?)\s+(\d+)(:.*)?$').firstMatch(raw);
    if (m != null) {
      final anyBook = m.group(1)!;
      final chapter = m.group(2)!;
      final versePart = m.group(3) ?? '';
      final refBook = provider.bibleService.displayToRef(anyBook);
      return '${refBook.toUpperCase()} $chapter${versePart.toUpperCase()}';
    }
    return raw.toUpperCase();
  }
}

// Private chapter page widget with fade animation and independent scroll
class _ChapterPage extends StatefulWidget {
  final String book;
  final int chapter;
  final Map<String, Map<int, String>> cache;
  final Future<String> Function(String, int) loader;
  final double fontScale;
  final BibleReaderThemeData themeData;
  final int? initialFocusVerse;
  final VoidCallback? onChapterCompleted; // Called when user taps "Complete Chapter"
  final bool Function() hasMetReadingThreshold; // Returns true if reading time threshold was met
  const _ChapterPage({
    super.key,
    required this.book,
    required this.chapter,
    required this.cache,
    required this.loader,
    required this.fontScale,
    required this.themeData,
    this.initialFocusVerse,
    this.onChapterCompleted,
    required this.hasMetReadingThreshold,
  });

  @override
  State<_ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<_ChapterPage> {
  String? _text;
  bool _loading = true;
  bool _showEndPanel = false;
  bool _showCompletionBanner = false;
  final Map<int, GlobalKey> _verseKeys = {};
  int? _focusedVerse;
  bool _didInitialFocus = false;
  final ScrollController _scrollController = ScrollController();
  
  // Complete Chapter eligibility tracking (v2.2)
  DateTime? _chapterLoadedAt; // Presence timer start
  bool _hasScrolled = false; // User started scrolling (via ScrollStartNotification)
  bool _isShortChapter = false; // Content fits viewport (no scroll needed)
  static const int _minPresenceSeconds = 12; // Minimum time on chapter screen
  
  // Live countdown timer for button label
  Timer? _countdownTimer;
  int _remainingSeconds = _minPresenceSeconds;
  
  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Start or restart the countdown timer when panel becomes visible
  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _updateRemainingSeconds();
    if (_remainingSeconds > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _countdownTimer?.cancel();
          return;
        }
        _updateRemainingSeconds();
        setState(() {}); // Rebuild to update button label
        if (_remainingSeconds <= 0) {
          _countdownTimer?.cancel();
        }
      });
    }
  }
  
  /// Update remaining seconds based on presence time
  void _updateRemainingSeconds() {
    if (_chapterLoadedAt == null) {
      _remainingSeconds = _minPresenceSeconds;
      return;
    }
    final elapsed = DateTime.now().difference(_chapterLoadedAt!).inSeconds;
    _remainingSeconds = (_minPresenceSeconds - elapsed).clamp(0, _minPresenceSeconds);
  }
  
  /// Get the button label based on eligibility
  String _getButtonLabel() {
    if (_isEligibleToComplete()) {
      return 'Complete Chapter';
    }
    _updateRemainingSeconds();
    if (_remainingSeconds > 0) {
      return 'Complete (${_remainingSeconds}s)';
    }
    return 'Complete Chapter';
  }
  
  /// Check if content fits viewport and mark as short chapter if so
  /// Uses actual scroll metrics from ScrollController after layout
  void _checkIfViewportFit() {
    if (!mounted || _isShortChapter || _showEndPanel) return;
    
    // Schedule check after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isShortChapter || _showEndPanel) return;
      
      // Check if scroll controller has position and if content fits viewport
      if (_scrollController.hasClients) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        // If content requires minimal or no scrolling, it's a viewport-fit chapter
        if (maxExtent <= 100) { // 100px threshold covers chapters that barely need scrolling
          setState(() {
            _isShortChapter = true;
            _showEndPanel = true;
          });
          _startCountdownTimer();
          return;
        }
      }
      
      // Fallback: If scroll controller not ready, retry after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted || _isShortChapter || _showEndPanel) return;
        
        if (_scrollController.hasClients) {
          final maxExtent = _scrollController.position.maxScrollExtent;
          if (maxExtent <= 100) {
            setState(() {
              _isShortChapter = true;
              _showEndPanel = true;
            });
            _startCountdownTimer();
          }
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _chapterLoadedAt = DateTime.now(); // Start presence timer
    _load();
  }

  @override
  void didUpdateWidget(covariant _ChapterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book != widget.book || oldWidget.chapter != widget.chapter) {
      // Reset engagement tracking for new chapter
      _chapterLoadedAt = DateTime.now();
      _hasScrolled = false;
      _isShortChapter = false;
      _countdownTimer?.cancel();
      _remainingSeconds = _minPresenceSeconds;
      _load();
    }
  }
  
  /// Check if Complete Chapter is eligible (v2.2 foolproof logic)
  /// Eligible when BOTH conditions met:
  /// A) Minimum presence time >= 12 seconds
  /// B) At least ONE engagement condition:
  ///    - reading threshold met (45s), OR
  ///    - short chapter (no scroll needed), OR
  ///    - user scrolled (detected via ScrollStartNotification), OR
  ///    - panel is visible (user reached end of content)
  bool _isEligibleToComplete() {
    // Condition A: minimum presence time
    if (_chapterLoadedAt == null) return false;
    final presence = DateTime.now().difference(_chapterLoadedAt!).inSeconds;
    if (presence < _minPresenceSeconds) return false;
    
    // Condition B: at least one engagement
    // Panel visibility (_showEndPanel) is an engagement signal - user either scrolled
    // to 92% of content or it's a short chapter that auto-revealed the panel
    final hasReadingThreshold = widget.hasMetReadingThreshold();
    return hasReadingThreshold || _isShortChapter || _hasScrolled || _showEndPanel;
  }
  
  /// Get message for why completion is disabled
  String _getDisabledReason() {
    if (_chapterLoadedAt == null) return 'Loading...';
    final presence = DateTime.now().difference(_chapterLoadedAt!).inSeconds;
    if (presence < _minPresenceSeconds) {
      final remaining = _minPresenceSeconds - presence;
      return 'Keep reading for $remaining more seconds';
    }
    return 'Scroll through the passage to continue';
  }

  Future<void> _load() async {
    final book = widget.book;
    final chapter = widget.chapter;
    final perBook = widget.cache[book];
    if (perBook != null && perBook.containsKey(chapter)) {
      final cached = perBook[chapter]!;
      setState(() {
        _text = cached;
        _loading = false;
      });
      // Short chapter detection for cached chapters - check actual scroll metrics
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfViewportFit();
      });
      return;
    }
    setState(() => _loading = true);
    final t = await widget.loader(book, chapter);
    if (!mounted) return;
    widget.cache.putIfAbsent(book, () => <int, String>{})[chapter] = t;
    setState(() {
      _text = t;
      _loading = false;
    });
    // Schedule short chapter detection after layout - check actual scroll metrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfViewportFit();
    });
    // After load, if an initial focus verse is present, schedule ensureVisible
    if (widget.initialFocusVerse != null && !_didInitialFocus) {
      _focusedVerse = widget.initialFocusVerse;
      _didInitialFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _verseKeys[_focusedVerse!];
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.15,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
        // Fade out the focus highlight after a brief moment
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) {
            setState(() => _focusedVerse = null);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: GamerColors.accent));
    }
    final text = _text ?? '';
    final fontScale = widget.fontScale;
    final themeData = widget.themeData;
    final showRed = context.select<SettingsProvider, bool>((sp) => sp.redLettersEnabled);
    final fontStyle = context.select<SettingsProvider, ReaderFontStyle>((sp) => sp.readerFontStyle);
    final verses = _parseVerses(text);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              // Track scroll start as engagement (user started interacting)
              if (n is ScrollStartNotification && !_hasScrolled) {
                setState(() => _hasScrolled = true);
              }
              // Detect chapters that fit viewport (short or medium chapters)
              // maxScrollExtent <= small threshold means content doesn't require scrolling
              if (n.metrics.maxScrollExtent <= 50) {
                if (!_isShortChapter) {
                  setState(() {
                    _isShortChapter = true;
                    _showEndPanel = true; // Always show panel for viewport-fit chapters
                  });
                  // Start countdown timer when panel becomes visible
                  _startCountdownTimer();
                }
                return false;
              }
              // Also track scroll distance as engagement (backup)
              if (!_hasScrolled && n.metrics.pixels > 20) {
                _hasScrolled = true;
              }
              final pct = n.metrics.pixels / n.metrics.maxScrollExtent;
              final shouldShow = pct >= 0.92; // Slightly earlier reveal (was 0.95)
              if (shouldShow != _showEndPanel) {
                setState(() => _showEndPanel = shouldShow);
                // Start countdown timer when panel becomes visible
                if (shouldShow) {
                  _startCountdownTimer();
                }
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              key: ValueKey('${widget.book}-${widget.chapter}-${text.hashCode}'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final v = verses[index];
                _verseKeys.putIfAbsent(v.number, () => GlobalKey(debugLabel: 'v_${v.number}'));
                final app = context.read<AppProvider>();
                final verseKey = app.verseKeyFor(widget.book, widget.chapter, v.number);
                final colorKey = app.getHighlightColorKey(verseKey);
                final isJesus = BibleRedLetterHelper.isJesusSpeaking(
                  bookName: widget.book,
                  chapter: widget.chapter,
                  verseNumber: v.number,
                );
                final bg = (colorKey == null)
                    ? null
                    : BibleReaderStyles.highlightColor(colorKey).withValues(alpha: 0.18);
                final isHighlighted = colorKey != null;
                final isFocus = (_focusedVerse != null && v.number == _focusedVerse);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => _showVerseActions(
                    verseKey: verseKey,
                    verseNumber: v.number,
                    verseText: v.text,
                  ),
                  child: AnimatedContainer(
                    key: _verseKeys[v.number],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? bg
                          : (isFocus ? GamerColors.accent.withValues(alpha: 0.08) : null),
                      borderRadius: BorderRadius.zero,
                      border: isHighlighted
                          ? Border(
                              left: BorderSide(
                                color: BibleReaderStyles
                                    .highlightColor(colorKey!)
                                    .withValues(alpha: 0.9),
                                width: 2.0,
                              ),
                            )
                          : null,
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${v.number} ',
                            style: BibleReaderStyles.verseNumber(fontScale, themeData, fontStyle: fontStyle),
                          ),
                          TextSpan(
                            text: v.text.trim(),
                            style: (showRed && isJesus)
                                ? BibleReaderStyles.jesusWords(fontScale, themeData, fontStyle: fontStyle)
                                : BibleReaderStyles.verseBody(fontScale, themeData, fontStyle: fontStyle),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Bottom-of-chapter reveal panel
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: IgnorePointer(
              ignoring: !_showEndPanel,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                offset: _showEndPanel ? Offset.zero : const Offset(0, 0.2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  opacity: _showEndPanel ? 1.0 : 0.0,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: GamerColors.darkCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: GamerColors.accent.withValues(alpha: 0.12),
                                border: Border.all(color: GamerColors.accent.withValues(alpha: 0.35), width: 1),
                              ),
                              child: const Icon(Icons.menu_book_outlined, color: GamerColors.accent),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You reached the end of this chapter',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isEligibleToComplete()
                                    ? () async {
                                        if (kDebugMode) {
                                          debugPrint('[CompleteChapter] pressed book=${widget.book} chapter=${widget.chapter} eligible=true');
                                        }
                                        HapticFeedback.lightImpact();
                                        final app = context.read<AppProvider>();
                                        // Record chapter completion (updates stats, weekly quest only if time threshold met)
                                        final hasMetThreshold = widget.hasMetReadingThreshold();
                                        await app.recordChapterRead(widget.book, widget.chapter, hasMetReadingThreshold: hasMetThreshold);
                                        if (kDebugMode) {
                                          debugPrint('[CompleteChapter] persisted=true');
                                        }
                                        // Notify parent about chapter completion (for daily quest tracking)
                                        widget.onChapterCompleted?.call();
                                        if (!mounted) return;
                                        RewardToast.showSuccess(
                                          context,
                                          title: 'Chapter completed',
                                          subtitle: '${widget.book} ${widget.chapter}',
                                        );
                                        try {
                                          final bookRef = app.bibleService.displayToRef(widget.book);
                                          await ProgressEngine.instance.emit(
                                            ProgressEvent.chapterCompleted(
                                              bookRef,
                                              widget.book,
                                              widget.chapter,
                                            ),
                                          );
                                        } catch (_) {}
                                        // Show a subtle in-page completion banner (+10 XP)
                                        if (mounted) {
                                          setState(() => _showCompletionBanner = true);
                                          Future.delayed(const Duration(milliseconds: 2600), () {
                                            if (mounted) {
                                              setState(() => _showCompletionBanner = false);
                                            }
                                          });
                                        }
                                      }
                                    : null, // Disabled when not eligible
                                child: Text(_getButtonLabel()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Builder(
                              builder: (ctx) {
                                // Use display name for quiz lookup (ChapterQuizService uses display names)
                                final quizAvailable = ChapterQuizService.getQuizForChapter(widget.book, widget.chapter) != null;
                                return OutlinedButton.icon(
                                  onPressed: quizAvailable
                                      ? () {
                                          final uri = Uri(path: '/chapter-quiz', queryParameters: {
                                            'book': widget.book,
                                            'chapter': '${widget.chapter}',
                                          });
                                          try {
                                            final app = ctx.read<AppProvider>();
                                            final bookRef = app.bibleService.displayToRef(widget.book);
                                            final diff = ctx.read<SettingsProvider>().preferredQuizDifficulty;
                                            ProgressEngine.instance.emit(
                                              ProgressEvent.chapterQuizStarted(bookRef, widget.chapter, diff.code),
                                            );
                                          } catch (_) {}
                                          context.push(uri.toString());
                                        }
                                      : null,
                                  icon: const Icon(Icons.quiz_outlined),
                                  label: Text(quizAvailable ? 'Take Chapter Quiz' : 'Quiz (Coming soon)'),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Small animated banner when chapter completion occurs
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: IgnorePointer(ignoring: !_showCompletionBanner, child: _CompletionBanner(visible: _showCompletionBanner)),
          ),
        ],
      ),
    );
  }

  Future<void> _showVerseActions({
    required String verseKey,
    required int verseNumber,
    required String verseText,
  }) {
    final app = context.read<AppProvider>();
    final current = app.getHighlightColorKey(verseKey);
    final title = 'Verse Actions — ${widget.book} ${widget.chapter}:$verseNumber';
    final isFav = app.isFavoriteVerse(verseKey);
    RewardToast.setBottomSheetOpen(true);
    return showModalBottomSheet(
      context: context,
      backgroundColor: GamerColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Section 1 — Favorite
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? GamerColors.neonPurple : GamerColors.textSecondary,
                  ),
                  title: Text(isFav ? 'Unfavorite verse' : 'Favorite verse'),
                  onTap: () async {
                    await app.toggleFavoriteVerse(verseKey);
                    if (mounted) Navigator.of(ctx).pop();
                  },
                ),

                const SizedBox(height: 12),

                // Section 2 — Journal
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Journal this verse'),
                  subtitle: const Text(
                    'Start a new entry with this verse',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  onTap: () async {
                    final ref = '${widget.book} ${widget.chapter}:$verseNumber';
                    final body = '$ref — "${verseText.trim()}"\n\n';
                    final refRoute = Uri(path: '/verses', queryParameters: {
                      'ref': ref,
                    }).toString();
                    Navigator.of(ctx).pop();
                    // Open Journal editor in create mode with prefilled content
                    RewardToast.setBottomSheetOpen(true);
                    await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (bctx) => JournalEditorSheet(
                        initialTitle: ref,
                        initialBody: body,
                        initialTags: const ['Study', 'Notes'],
                        initialLinkedRef: ref,
                        initialLinkedRefRoute: refRoute,
                      ),
                    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
                  },
                ),

                // Section 2 — Memorize
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Memorize this verse'),
                  subtitle: const Text(
                    'Open memorization practice',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  onTap: () async {
                    // Ensure it appears in memorization list by favoriting if needed
                    if (!app.isFavoriteVerse(verseKey)) {
                      await app.toggleFavoriteVerse(verseKey);
                    }
                    final uri = Uri(path: '/memorization-practice', queryParameters: {
                      'key': verseKey,
                    });
                    Navigator.of(ctx).pop();
                    if (mounted) context.push(uri.toString());
                  },
                ),

                const SizedBox(height: 12),

                // Section 3 — Highlight
                Text('Highlight', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: GamerColors.accent)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HighlightChip(
                      label: 'Sun',
                      color: BibleReaderStyles.highlightColor('sun'),
                      selected: current == 'sun',
                      onTap: () async {
                        await app.setHighlight(verseKey, 'sun');
                        if (mounted) Navigator.of(ctx).pop();
                      },
                    ),
                    _HighlightChip(
                      label: 'Mint',
                      color: BibleReaderStyles.highlightColor('mint'),
                      selected: current == 'mint',
                      onTap: () async {
                        await app.setHighlight(verseKey, 'mint');
                        if (mounted) Navigator.of(ctx).pop();
                      },
                    ),
                    _HighlightChip(
                      label: 'Violet',
                      color: BibleReaderStyles.highlightColor('violet'),
                      selected: current == 'violet',
                      onTap: () async {
                        await app.setHighlight(verseKey, 'violet');
                        if (mounted) Navigator.of(ctx).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (current != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        await app.clearHighlight(verseKey);
                        if (mounted) Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.clear, color: GamerColors.textSecondary),
                      label: const Text(
                        'Clear highlight',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Section 4 — Copy
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy verse'),
                  onTap: () async {
                    final payload = '${widget.book} ${widget.chapter}:$verseNumber — ${verseText.trim()}';
                    await Clipboard.setData(ClipboardData(text: payload));
                    RewardToast.showSuccess(context, title: 'Copied to clipboard');
                    if (mounted) Navigator.of(ctx).pop();
                  },
                ),

                // Section 5 — Share
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.ios_share),
                  title: const Text('Share verse'),
                  onTap: () async {
                    final payload = '${widget.book} ${widget.chapter}:$verseNumber — ${verseText.trim()}';
                    await Share.share(
                      payload,
                      subject: 'Scripture Quest™ — ${widget.book} ${widget.chapter}:$verseNumber',
                    );
                    if (mounted) Navigator.of(ctx).pop();
                  },
                ),
              ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(() => RewardToast.setBottomSheetOpen(false));
  }

  // Parse lines like "1 In the beginning ..." into (number, text)
  List<_ParsedVerse> _parseVerses(String chapterText) {
    final lines = chapterText.split(RegExp(r'\r?\n'));
    final list = <_ParsedVerse>[];
    final reg = RegExp(r'^\s*(\d+)\s+(.+)$');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final m = reg.firstMatch(trimmed);
      if (m == null) {
        // Skip non-verse lines in case of headers or notes
        continue;
      }
      final num = int.tryParse(m.group(1) ?? '') ?? 0;
      final body = (m.group(2) ?? '').trim();
      if (num > 0 && body.isNotEmpty) {
        list.add(_ParsedVerse(number: num, text: body));
      }
    }
    return list;
  }
}

class _ParsedVerse {
  final int number;
  final String text;
  _ParsedVerse({required this.number, required this.text});
}

class _HighlightChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _HighlightChip({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color.withValues(alpha: 0.25) : color.withValues(alpha: 0.12);
    final border = selected ? color.withValues(alpha: 0.55) : color.withValues(alpha: 0.35);
    final textColor = Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _ChapterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool read;
  final VoidCallback onTap;
  const _ChapterChip({
    required this.label,
    required this.selected,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? GamerColors.accent.withValues(alpha: 0.22)
        : GamerColors.accent.withValues(alpha: 0.10);
    final border = selected
        ? GamerColors.accent.withValues(alpha: 0.60)
        : GamerColors.accent.withValues(alpha: 0.35);
    final textColor = Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (read) ...[
              const Icon(Icons.check, color: GamerColors.success, size: 14),
              const SizedBox(width: 6),
            ],
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _BookChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _BookChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = GamerColors.accent;
    final bg = selected ? base.withValues(alpha: 0.22) : base.withValues(alpha: 0.10);
    final border = selected ? base.withValues(alpha: 0.60) : base.withValues(alpha: 0.35);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.menu_book_outlined, color: GamerColors.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _segButton({required String label, required bool selected, required VoidCallback onTap}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? GamerColors.accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? GamerColors.accent.withValues(alpha: 0.6) : Colors.transparent, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ),
  );
}

class _CompletionBanner extends StatelessWidget {
  final bool visible;
  const _CompletionBanner({required this.visible});

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      offset: visible ? Offset.zero : const Offset(0, 0.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        opacity: visible ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            color: GamerColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GamerColors.success.withValues(alpha: 0.12),
                  border: Border.all(color: GamerColors.success.withValues(alpha: 0.45), width: 1),
                ),
                child: const Icon(Icons.check, color: GamerColors.success, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Chapter complete! +10 XP',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Great job staying in the Word.',
                      style: TextStyle(color: GamerColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderStyleChips extends StatelessWidget {
  final ReaderColorScheme current;
  final ValueChanged<ReaderColorScheme> onChanged;
  const _ReaderStyleChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = const [
      ReaderColorScheme.paper,
      ReaderColorScheme.sepia,
      ReaderColorScheme.night,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final e in entries)
          _SchemeChip(
            label: _label(e),
            selected: current == e,
            onTap: () => onChanged(e),
          ),
      ],
    );
  }

  String _label(ReaderColorScheme s) {
    switch (s) {
      case ReaderColorScheme.sepia:
        return 'Sepia';
      case ReaderColorScheme.night:
        return 'Night';
      case ReaderColorScheme.paper:
      default:
        return 'Paper';
    }
  }
}

class _SchemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SchemeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = GamerColors.accent;
    final bg = selected ? base.withValues(alpha: 0.20) : base.withValues(alpha: 0.10);
    final border = selected ? base.withValues(alpha: 0.65) : base.withValues(alpha: 0.35);
    final textColor = Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? GamerColors.neonCyan : GamerColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// (Old _ReaderSettingsSheet removed; text size is now controlled via chips in the Bible Menu.)

// Removed inline verse favorite button to reduce on-page chrome; favorites now live in the long-press sheet.

class _FontStyleChips extends StatelessWidget {
  final ReaderFontStyle current;
  final ValueChanged<ReaderFontStyle> onChanged;
  const _FontStyleChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = const [
      ReaderFontStyle.classicSerif,
      ReaderFontStyle.cleanSans,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final e in entries)
          _SchemeChip(
            label: _label(e),
            selected: current == e,
            onTap: () => onChanged(e),
          ),
      ],
    );
  }

  String _label(ReaderFontStyle s) {
    switch (s) {
      case ReaderFontStyle.cleanSans:
        return 'Clean';
      case ReaderFontStyle.classicSerif:
      default:
        return 'Classic';
    }
  }
}

class _TextSizeChips extends StatelessWidget {
  final ReaderTextSize current;
  final ValueChanged<ReaderTextSize> onChanged;
  const _TextSizeChips({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = const [
      ReaderTextSize.small,
      ReaderTextSize.medium,
      ReaderTextSize.large,
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final e in entries)
          _SchemeChip(
            label: _label(e),
            selected: current == e,
            onTap: () => onChanged(e),
          ),
      ],
    );
  }

  String _label(ReaderTextSize s) {
    switch (s) {
      case ReaderTextSize.small:
        return 'Small';
      case ReaderTextSize.large:
        return 'Large';
      case ReaderTextSize.medium:
      default:
        return 'Medium';
    }
  }
}

class _TextSizeSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _TextSizeSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.8, 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.text_decrease, color: GamerColors.textSecondary),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: GamerColors.accent,
                  inactiveTrackColor: GamerColors.accent.withValues(alpha: 0.25),
                  thumbColor: GamerColors.accent,
                  overlayColor: GamerColors.accent.withValues(alpha: 0.12),
                ),
                child: Slider(
                  min: 0.8,
                  max: 1.4,
                  value: v,
                  onChanged: onChanged,
                ),
              ),
            ),
            const Icon(Icons.text_increase, color: GamerColors.textSecondary),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Current: ${(v * 100).round()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary),
        ),
      ],
    );
  }
}
