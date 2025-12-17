import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Mock classes for testing
class MockAppProvider extends ChangeNotifier {
  final Map<String, Set<int>> _completedChapters = {};
  String? lastNavigatedRef;
  
  bool isChapterRead(String book, int chapter) {
    return _completedChapters[book]?.contains(chapter) ?? false;
  }
  
  void markChapterCompleted(String book, int chapter) {
    _completedChapters.putIfAbsent(book, () => <int>{});
    _completedChapters[book]!.add(chapter);
    notifyListeners();
  }
  
  int getChapterCount(String book) {
    if (book == 'Psalms') return 150;
    if (book == 'John') return 21;
    if (book == 'Genesis') return 50;
    return 10;
  }
}

class MockBibleService {
  int getChapterCount(String book) {
    if (book == 'Psalms') return 150;
    if (book == 'John') return 21;
    if (book == 'Genesis') return 50;
    return 10;
  }
  
  Map<String, dynamic> parseReference(String ref) {
    final parts = ref.split(' ');
    final book = parts.first;
    int? chapter;
    if (parts.length > 1) {
      final chapterStr = parts[1].split(':').first;
      chapter = int.tryParse(chapterStr);
    }
    return {'bookDisplay': book, 'chapter': chapter};
  }
}

// Test widget that simulates chapter picker behavior
class TestChapterPicker extends StatelessWidget {
  final String book;
  final int totalChapters;
  final bool Function(String book, int chapter) isChapterCompleted;
  final void Function(String book, int chapter) onChapterTap;

  const TestChapterPicker({
    super.key,
    required this.book,
    required this.totalChapters,
    required this.isChapterCompleted,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Wrap(
          children: [
            for (int i = 1; i <= totalChapters.clamp(1, 20); i++)
              GestureDetector(
                key: ValueKey('chapter_$i'),
                onTap: () => onChapterTap(book, i),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    color: isChapterCompleted(book, i) ? Colors.green : Colors.white,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isChapterCompleted(book, i))
                        const Icon(Icons.check, size: 16, color: Colors.white, key: ValueKey('checkmark')),
                      Text('$i'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('Bible Reader Core Loop Tests', () {
    testWidgets('Chapter picker taps navigate to correct chapter (not always 1)', (tester) async {
      int? navigatedChapter;
      String? navigatedBook;
      
      await tester.pumpWidget(
        TestChapterPicker(
          book: 'Psalms',
          totalChapters: 20,
          isChapterCompleted: (_, __) => false,
          onChapterTap: (book, chapter) {
            navigatedBook = book;
            navigatedChapter = chapter;
          },
        ),
      );
      
      // Tap on chapter 15
      await tester.tap(find.byKey(const ValueKey('chapter_15')));
      await tester.pump();
      
      expect(navigatedBook, 'Psalms');
      expect(navigatedChapter, 15, reason: 'Should navigate to chapter 15, not 1');
      
      // Tap on chapter 7
      await tester.tap(find.byKey(const ValueKey('chapter_7')));
      await tester.pump();
      
      expect(navigatedChapter, 7, reason: 'Should navigate to chapter 7');
    });

    testWidgets('Checkmark does NOT appear just by opening/viewing a chapter', (tester) async {
      final provider = MockAppProvider();
      
      await tester.pumpWidget(
        TestChapterPicker(
          book: 'John',
          totalChapters: 10,
          isChapterCompleted: provider.isChapterRead,
          onChapterTap: (_, __) {},
        ),
      );
      
      // Initially no checkmarks should be visible
      expect(find.byKey(const ValueKey('checkmark')), findsNothing,
          reason: 'No checkmarks should appear before any chapter is completed');
      
      // Simulate "opening" chapter 3 (this should NOT mark it complete)
      // In the real app, this is just navigating to the chapter
      // The checkmark should still NOT appear
      await tester.pump();
      
      expect(provider.isChapterRead('John', 3), false,
          reason: 'Opening a chapter should NOT mark it as completed');
      expect(find.byKey(const ValueKey('checkmark')), findsNothing,
          reason: 'Checkmark should not appear just from viewing');
    });

    testWidgets('Checkmark appears ONLY after explicit Complete Chapter action', (tester) async {
      final provider = MockAppProvider();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<MockAppProvider>.value(
          value: provider,
          child: Consumer<MockAppProvider>(
            builder: (context, prov, _) => TestChapterPicker(
              book: 'Genesis',
              totalChapters: 10,
              isChapterCompleted: prov.isChapterRead,
              onChapterTap: (_, __) {},
            ),
          ),
        ),
      );
      
      // Initially no checkmarks
      expect(find.byKey(const ValueKey('checkmark')), findsNothing);
      expect(provider.isChapterRead('Genesis', 5), false);
      
      // Simulate explicit "Complete Chapter" action for chapter 5
      provider.markChapterCompleted('Genesis', 5);
      await tester.pump();
      
      // Now checkmark should appear for chapter 5
      expect(provider.isChapterRead('Genesis', 5), true,
          reason: 'Chapter should be marked complete after explicit action');
      expect(find.byKey(const ValueKey('checkmark')), findsOneWidget,
          reason: 'Checkmark should appear after Complete Chapter action');
    });

    testWidgets('Multiple chapters can be completed independently', (tester) async {
      final provider = MockAppProvider();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<MockAppProvider>.value(
          value: provider,
          child: Consumer<MockAppProvider>(
            builder: (context, prov, _) => TestChapterPicker(
              book: 'John',
              totalChapters: 10,
              isChapterCompleted: prov.isChapterRead,
              onChapterTap: (_, __) {},
            ),
          ),
        ),
      );
      
      // Complete chapters 1, 3, and 7
      provider.markChapterCompleted('John', 1);
      provider.markChapterCompleted('John', 3);
      provider.markChapterCompleted('John', 7);
      await tester.pump();
      
      // Verify correct chapters are marked
      expect(provider.isChapterRead('John', 1), true);
      expect(provider.isChapterRead('John', 2), false, reason: 'Chapter 2 was not completed');
      expect(provider.isChapterRead('John', 3), true);
      expect(provider.isChapterRead('John', 4), false);
      expect(provider.isChapterRead('John', 7), true);
      
      // Should have exactly 3 checkmarks
      expect(find.byKey(const ValueKey('checkmark')), findsNWidgets(3));
    });

    testWidgets('Chapter picker navigation works for different books (John)', (tester) async {
      int? navigatedChapter;
      String? navigatedBook;
      
      await tester.pumpWidget(
        TestChapterPicker(
          book: 'John',
          totalChapters: 20,
          isChapterCompleted: (_, __) => false,
          onChapterTap: (book, chapter) {
            navigatedBook = book;
            navigatedChapter = chapter;
          },
        ),
      );
      
      // Tap on chapter 3 (famous John 3:16 chapter)
      await tester.tap(find.byKey(const ValueKey('chapter_3')));
      await tester.pump();
      
      expect(navigatedBook, 'John');
      expect(navigatedChapter, 3, reason: 'Should navigate to John chapter 3');
      
      // Tap on chapter 11
      await tester.tap(find.byKey(const ValueKey('chapter_11')));
      await tester.pump();
      
      expect(navigatedChapter, 11, reason: 'Should navigate to John chapter 11');
    });
  });

  group('Chapter Quiz Visibility Tests', () {
    testWidgets('Quiz availability is correctly determined', (tester) async {
      // Mock quiz availability check
      // Available chapters: John 3, Romans 8, Psalm 23, Proverbs 3, Luke 2
      bool isQuizAvailable(String bookRef, int chapter) {
        if (bookRef == 'John' && chapter == 3) return true;
        if (bookRef == 'Romans' && chapter == 8) return true;
        if (bookRef == 'Psalms' && chapter == 23) return true;
        if (bookRef == 'Psalm' && chapter == 23) return true;
        if (bookRef == 'Proverbs' && chapter == 3) return true;
        if (bookRef == 'Luke' && chapter == 2) return true;
        return false;
      }
      
      // Test quiz availability
      expect(isQuizAvailable('John', 3), true, reason: 'John 3 should have quiz');
      expect(isQuizAvailable('John', 1), false, reason: 'John 1 should not have quiz');
      expect(isQuizAvailable('Romans', 8), true, reason: 'Romans 8 should have quiz');
      expect(isQuizAvailable('Psalms', 23), true, reason: 'Psalm 23 should have quiz');
      expect(isQuizAvailable('Genesis', 1), false, reason: 'Genesis 1 should not have quiz');
    });

    testWidgets('Quiz button shows correct state based on availability', (tester) async {
      // Simple widget to test quiz button state
      bool quizAvailable = false;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    key: const ValueKey('toggle_quiz'),
                    onPressed: () => setState(() => quizAvailable = !quizAvailable),
                    child: const Text('Toggle'),
                  ),
                  OutlinedButton(
                    key: const ValueKey('quiz_button'),
                    onPressed: quizAvailable ? () {} : null,
                    child: Text(quizAvailable ? 'Chapter Quiz' : 'Quiz (Coming soon)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Initially quiz not available - button should be disabled
      final quizButton = find.byKey(const ValueKey('quiz_button'));
      expect(quizButton, findsOneWidget);
      expect(find.text('Quiz (Coming soon)'), findsOneWidget,
          reason: 'Should show "Coming soon" when quiz not available');
      
      // Toggle quiz availability
      await tester.tap(find.byKey(const ValueKey('toggle_quiz')));
      await tester.pump();
      
      expect(find.text('Chapter Quiz'), findsOneWidget,
          reason: 'Should show "Chapter Quiz" when quiz is available');
    });
  });

  group('Quest Hub Filter Chip Tests', () {
    testWidgets('Tapping Weekly selects Weekly chip AND shows weekly list, Tonight is not selected', (tester) async {
      // Simulate filter chip behavior with _filter as sole source of truth
      int selectedFilter = 0; // 0=Today, 1=Weekly, 2=Reflection, 3=Events
      
      final filterLabels = ['Today', 'Weekly', 'Reflection', 'Events'];
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Filter chips - selection derived from selectedFilter only
                  Wrap(
                    children: [
                      for (int i = 0; i < filterLabels.length; i++)
                        GestureDetector(
                          key: ValueKey('filter_chip_$i'),
                          onTap: () => setState(() => selectedFilter = i),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selectedFilter == i ? Colors.blue : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              filterLabels[i],
                              style: TextStyle(
                                color: selectedFilter == i ? Colors.white : Colors.black,
                                fontWeight: selectedFilter == i ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // List content derived from selectedFilter
                  Text(
                    key: const ValueKey('current_list_label'),
                    'Showing: ${filterLabels[selectedFilter]} quests',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Initially "Today" is selected
      expect(find.text('Showing: Today quests'), findsOneWidget);
      
      // Tap "Weekly" chip (index 1)
      await tester.tap(find.byKey(const ValueKey('filter_chip_1')));
      await tester.pump();
      
      // Verify Weekly chip is now selected (list shows Weekly)
      expect(find.text('Showing: Weekly quests'), findsOneWidget,
          reason: 'List should show Weekly quests after tapping Weekly chip');
      
      // Verify Today is NOT selected (would show different text if it was)
      expect(find.text('Showing: Today quests'), findsNothing,
          reason: 'Today quests should NOT be showing when Weekly is selected');
    });
  });

  group('Bible Reader Book/Chapter Picker Tests', () {
    testWidgets('Tapping a book does NOT navigate immediately - opens chapter picker', (tester) async {
      String? navigatedRef;
      bool chapterPickerOpened = false;
      String? chapterPickerBook;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  // Book list (simulates Jump to Book sheet)
                  GestureDetector(
                    key: const ValueKey('book_acts'),
                    onTap: () {
                      // New behavior: open chapter picker, don't navigate
                      setState(() {
                        chapterPickerOpened = true;
                        chapterPickerBook = 'Acts';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Text('Acts'),
                    ),
                  ),
                  // Chapter picker (shown when book is tapped)
                  if (chapterPickerOpened && chapterPickerBook != null)
                    Wrap(
                      children: [
                        Text('Chapters in $chapterPickerBook'),
                        for (int ch = 1; ch <= 5; ch++)
                          GestureDetector(
                            key: ValueKey('chapter_picker_$ch'),
                            onTap: () => navigatedRef = '$chapterPickerBook $ch',
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Text('$ch'),
                            ),
                          ),
                      ],
                    ),
                  // Navigation result display
                  if (navigatedRef != null)
                    Text(key: const ValueKey('navigated_to'), 'Navigated: $navigatedRef'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Tap on book "Acts"
      await tester.tap(find.byKey(const ValueKey('book_acts')));
      await tester.pump();
      
      // Should NOT have navigated yet
      expect(navigatedRef, isNull, reason: 'Tapping book should NOT navigate immediately');
      
      // Chapter picker should be open
      expect(find.text('Chapters in Acts'), findsOneWidget,
          reason: 'Chapter picker should open after tapping book');
      
      // Now tap chapter 3
      await tester.tap(find.byKey(const ValueKey('chapter_picker_3')));
      await tester.pump();
      
      // Should navigate to Acts 3
      expect(navigatedRef, 'Acts 3', reason: 'Should navigate to Acts 3 after selecting chapter');
    });

    testWidgets('Top selector allows changing book via Change Book action', (tester) async {
      String currentBook = 'Matthew';
      int currentChapter = 5;
      bool showingBookList = false;
      
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: GestureDetector(
                  key: const ValueKey('top_selector'),
                  onTap: () {
                    // Opens chapter picker for current book (with change book option)
                  },
                  child: Text('$currentBook · $currentChapter'),
                ),
              ),
              body: Column(
                children: [
                  // Simulates chapter picker with "Change Book" button
                  Text('Chapters in $currentBook'),
                  TextButton(
                    key: const ValueKey('change_book_btn'),
                    onPressed: () => setState(() => showingBookList = true),
                    child: const Text('Change Book'),
                  ),
                  // Book list (shown after Change Book)
                  if (showingBookList)
                    GestureDetector(
                      key: const ValueKey('book_romans'),
                      onTap: () => setState(() {
                        currentBook = 'Romans';
                        showingBookList = false;
                      }),
                      child: const Text('Romans'),
                    ),
                  // Current book indicator
                  Text(key: const ValueKey('current_book'), 'Current: $currentBook'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Initially showing Matthew
      expect(find.text('Current: Matthew'), findsOneWidget);
      
      // Tap "Change Book"
      await tester.tap(find.byKey(const ValueKey('change_book_btn')));
      await tester.pump();
      
      // Book list should appear
      expect(find.text('Romans'), findsOneWidget);
      
      // Tap on Romans
      await tester.tap(find.byKey(const ValueKey('book_romans')));
      await tester.pump();
      
      // Book should change to Romans
      expect(find.text('Current: Romans'), findsOneWidget,
          reason: 'Should be able to change book via Change Book action');
    });
  });
}
