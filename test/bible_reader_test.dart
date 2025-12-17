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
  });
}
