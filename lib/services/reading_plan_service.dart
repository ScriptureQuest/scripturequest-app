import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/reading_plan.dart';
import 'package:level_up_your_faith/services/bible_service.dart';

/// Provides client-side reading plan seeds and helpers.
class ReadingPlanService {
  static final BibleService _bible = BibleService.instance;

  static List<ReadingPlan> getSeeds() {
    return [
      _journeyThroughJohn(),
      _psalmsOfComfort7(),
      _wisdomForLife10(),
      _storyOfJesusHighlights7(),
      _gospelsIn30Days(),
      _wisdomIn31Days(),
      _newTestamentIn90Days(),
    ];
  }

  static ReadingPlan? getById(String id) {
    try {
      return getSeeds().firstWhere((p) => p.planId == id);
    } catch (_) {
      return null;
    }
  }

  static ReadingPlan _gospelsIn30Days() {
    // Gospel order and chapters
    final order = [
      {'book': 'Matthew', 'chapters': _bible.getChapterCount('Matthew')},
      {'book': 'Mark', 'chapters': _bible.getChapterCount('Mark')},
      {'book': 'Luke', 'chapters': _bible.getChapterCount('Luke')},
      {'book': 'John', 'chapters': _bible.getChapterCount('John')},
    ];
    final refs = <String>[];
    for (final b in order) {
      final book = b['book'] as String;
      final c = b['chapters'] as int;
      for (int ch = 1; ch <= c; ch++) {
        refs.add('$book $ch');
      }
    }
    final total = refs.length; // 89
    final targetDays = 30;
    final chunkSize = (total / targetDays).ceil(); // ~3
    final days = <ReadingPlanStep>[];
    int idx = 0;
    for (int day = 0; day < targetDays && idx < refs.length; day++) {
      final end = (idx + chunkSize) > refs.length ? refs.length : (idx + chunkSize);
      final slice = refs.sublist(idx, end);
      days.add(_stepFromSlice(day, slice, baseLabel: 'Day ${day + 1}'));
      idx = end;
    }

    return ReadingPlan(
      planId: 'plan_gospels_30',
      title: 'Gospels in 30 Days',
      subtitle: 'Walk with Jesus through Matthew, Mark, Luke, and John',
      description: 'A peaceful journey through the four Gospels with gentle daily portions.',
      days: days,
    );
  }

  static ReadingPlan _wisdomIn31Days() {
    // Gentle: Proverbs 1..31 as daily steps
    final days = <ReadingPlanStep>[];
    for (int i = 1; i <= 31; i++) {
      final refs = ['Proverbs $i'];
      days.add(ReadingPlanStep(
        stepIndex: i - 1,
        referenceList: refs,
        friendlyLabel: 'Day $i: Proverbs $i',
      ));
    }
    return ReadingPlan(
      planId: 'plan_wisdom_31',
      title: 'Wisdom in 31 Days',
      subtitle: 'Proverbs daily — a calm rhythm of wisdom',
      description: 'A peaceful month in Proverbs. Optional Psalms can be added as you wish.',
      days: days,
    );
  }

  static ReadingPlan _newTestamentIn90Days() {
    // NT books (Matthew .. Revelation) using BibleService ordering
    final ntStartIndex = BibleService.instance.getAllBooks().indexOf('Matthew');
    final books = BibleService.instance.getAllBooks().sublist(ntStartIndex);
    final refs = <String>[];
    for (final b in books) {
      final chapters = _bible.getChapterCount(b);
      for (int ch = 1; ch <= chapters; ch++) {
        refs.add('$b $ch');
      }
    }
    final total = refs.length; // 260
    const targetDays = 90;
    final chunkSize = (total / targetDays).ceil(); // ~3
    final days = <ReadingPlanStep>[];
    int idx = 0;
    for (int day = 0; day < targetDays && idx < refs.length; day++) {
      final end = (idx + chunkSize) > refs.length ? refs.length : (idx + chunkSize);
      final slice = refs.sublist(idx, end);
      days.add(_stepFromSlice(day, slice, baseLabel: 'Day ${day + 1}'));
      idx = end;
    }
    return ReadingPlan(
      planId: 'plan_nt_90',
      title: 'New Testament in 90 Days',
      subtitle: 'A steady walk through the New Testament',
      description: 'Gentle, sequential readings across the New Testament. No pressure. Walk in peace.',
      days: days,
    );
  }

  static ReadingPlanStep _stepFromSlice(int index, List<String> slice, {required String baseLabel}) {
    // Try to build a friendly label: if all refs within one book and contiguous, show range
    String label;
    if (slice.isEmpty) {
      label = '$baseLabel: (Rest)';
    } else {
      // Parse first and last for simple labels
      final first = slice.first;
      final last = slice.last;
      final firstBook = _bible.parseReference(first)['bookDisplay']?.toString() ?? first;
      final firstCh = _bible.parseReference(first)['chapter'] as int?;
      final lastBook = _bible.parseReference(last)['bookDisplay']?.toString() ?? last;
      final lastCh = _bible.parseReference(last)['chapter'] as int?;
      if (firstBook == lastBook && firstCh != null && lastCh != null && slice.length > 1) {
        label = '$baseLabel: Read $firstBook $firstCh–$lastCh';
      } else {
        // Mixed or single
        if (slice.length == 1) {
          label = '$baseLabel: Read ${slice.first}';
        } else {
          // Take up to two entries to keep short
          final preview = slice.take(2).join(', ');
          label = '$baseLabel: Read $preview';
        }
      }
    }
    return ReadingPlanStep(stepIndex: index, referenceList: List<String>.from(slice), friendlyLabel: label);
  }

  // ========= New Plans (v1.0 content expansion) =========
  static ReadingPlan _journeyThroughJohn() {
    // 12 gentle days through John 1–12 (one chapter per day)
    final days = <ReadingPlanStep>[
      ReadingPlanStep(stepIndex: 0, referenceList: const ['John 1'], friendlyLabel: 'Day 1: In the beginning — the Word and the Light'),
      ReadingPlanStep(stepIndex: 1, referenceList: const ['John 2'], friendlyLabel: 'Day 2: Water into wine — a quiet miracle'),
      ReadingPlanStep(stepIndex: 2, referenceList: const ['John 3'], friendlyLabel: 'Day 3: God so loved the world — hope for all'),
      ReadingPlanStep(stepIndex: 3, referenceList: const ['John 4'], friendlyLabel: 'Day 4: Living water — the woman at the well'),
      ReadingPlanStep(stepIndex: 4, referenceList: const ['John 5'], friendlyLabel: 'Day 5: Rise and walk — Jesus brings healing'),
      ReadingPlanStep(stepIndex: 5, referenceList: const ['John 6'], friendlyLabel: 'Day 6: Bread of life — trust in His care'),
      ReadingPlanStep(stepIndex: 6, referenceList: const ['John 7'], friendlyLabel: 'Day 7: Come and drink — a heart at rest'),
      ReadingPlanStep(stepIndex: 7, referenceList: const ['John 8'], friendlyLabel: 'Day 8: I am the Light of the world'),
      ReadingPlanStep(stepIndex: 8, referenceList: const ['John 9'], friendlyLabel: 'Day 9: I was blind, now I see'),
      ReadingPlanStep(stepIndex: 9, referenceList: const ['John 10'], friendlyLabel: 'Day 10: The Good Shepherd knows His sheep'),
      ReadingPlanStep(stepIndex: 10, referenceList: const ['John 11'], friendlyLabel: 'Day 11: Lazarus — Jesus brings life'),
      ReadingPlanStep(stepIndex: 11, referenceList: const ['John 12'], friendlyLabel: 'Day 12: Hosanna — Jesus enters Jerusalem'),
    ];
    return ReadingPlan(
      planId: 'plan_john_12',
      title: 'Journey Through John',
      subtitle: 'A calm walk through John 1–12',
      description: 'Twelve gentle days to meet Jesus in the Gospel of John. Kid‑friendly notes each day.',
      days: days,
    );
  }

  static ReadingPlan _psalmsOfComfort7() {
    // 7 days of comforting psalms
    final days = <ReadingPlanStep>[
      ReadingPlanStep(stepIndex: 0, referenceList: const ['Psalm 23'], friendlyLabel: 'Day 1: Psalm 23 — The Lord is my Shepherd'),
      ReadingPlanStep(stepIndex: 1, referenceList: const ['Psalm 27'], friendlyLabel: 'Day 2: Psalm 27 — The Lord is my light'),
      ReadingPlanStep(stepIndex: 2, referenceList: const ['Psalm 34'], friendlyLabel: 'Day 3: Psalm 34 — Taste and see His goodness'),
      ReadingPlanStep(stepIndex: 3, referenceList: const ['Psalm 46'], friendlyLabel: 'Day 4: Psalm 46 — God is our refuge and strength'),
      ReadingPlanStep(stepIndex: 4, referenceList: const ['Psalm 91'], friendlyLabel: 'Day 5: Psalm 91 — Rest in the shadow of the Almighty'),
      ReadingPlanStep(stepIndex: 5, referenceList: const ['Psalm 121'], friendlyLabel: 'Day 6: Psalm 121 — My help comes from the Lord'),
      ReadingPlanStep(stepIndex: 6, referenceList: const ['Psalm 139'], friendlyLabel: 'Day 7: Psalm 139 — Wonderfully made and fully known'),
    ];
    return ReadingPlan(
      planId: 'plan_psalms_comfort_7',
      title: 'Psalms of Comfort',
      subtitle: 'Seven days of calm and courage',
      description: 'A week of psalms that steady the heart and point us to God’s care.',
      days: days,
    );
  }

  static ReadingPlan _wisdomForLife10() {
    // 10 themed days in Proverbs (kid‑friendly summaries)
    final days = <ReadingPlanStep>[
      ReadingPlanStep(stepIndex: 0, referenceList: const ['Proverbs 1'], friendlyLabel: 'Day 1: Wisdom begins — listen and learn'),
      ReadingPlanStep(stepIndex: 1, referenceList: const ['Proverbs 3'], friendlyLabel: 'Day 2: Trust in the Lord with all your heart'),
      ReadingPlanStep(stepIndex: 2, referenceList: const ['Proverbs 4'], friendlyLabel: 'Day 3: Guard your heart — choose good paths'),
      ReadingPlanStep(stepIndex: 3, referenceList: const ['Proverbs 15'], friendlyLabel: 'Day 4: Words that build up — gentle answers'),
      ReadingPlanStep(stepIndex: 4, referenceList: const ['Proverbs 17'], friendlyLabel: 'Day 5: Friends and family — love stays close'),
      ReadingPlanStep(stepIndex: 5, referenceList: const ['Proverbs 16'], friendlyLabel: 'Day 6: Choices and plans — walk with God'),
      ReadingPlanStep(stepIndex: 6, referenceList: const ['Proverbs 6'], friendlyLabel: 'Day 7: Diligence — small steps with steady hands'),
      ReadingPlanStep(stepIndex: 7, referenceList: const ['Proverbs 11'], friendlyLabel: 'Day 8: Humility and kindness — be a blessing'),
      ReadingPlanStep(stepIndex: 8, referenceList: const ['Proverbs 19'], friendlyLabel: 'Day 9: Generosity and patience — slow to anger'),
      ReadingPlanStep(stepIndex: 9, referenceList: const ['Proverbs 22'], friendlyLabel: 'Day 10: Wisdom over riches — choose what lasts'),
    ];
    return ReadingPlan(
      planId: 'plan_proverbs_wisdom_10',
      title: 'Wisdom for Life',
      subtitle: 'Ten days in Proverbs',
      description: 'Short, practical themes from Proverbs to guide everyday life. Kid‑friendly and gentle.',
      days: days,
    );
  }

  static ReadingPlan _storyOfJesusHighlights7() {
    // 7 days — high‑level highlights across the Gospels
    final days = <ReadingPlanStep>[
      ReadingPlanStep(stepIndex: 0, referenceList: const ['Luke 2'], friendlyLabel: 'Day 1: Birth of Jesus — good news of great joy'),
      ReadingPlanStep(stepIndex: 1, referenceList: const ['Matthew 3'], friendlyLabel: 'Day 2: Baptism — the Father’s delight'),
      ReadingPlanStep(stepIndex: 2, referenceList: const ['Matthew 5', 'Matthew 6', 'Matthew 7'], friendlyLabel: 'Day 3: Teachings — the Sermon on the Mount'),
      ReadingPlanStep(stepIndex: 3, referenceList: const ['Mark 4', 'Mark 5'], friendlyLabel: 'Day 4: Miracles — wind, waves, and healing'),
      ReadingPlanStep(stepIndex: 4, referenceList: const ['John 11'], friendlyLabel: 'Day 5: Lazarus — Jesus shows His power over death'),
      ReadingPlanStep(stepIndex: 5, referenceList: const ['John 19'], friendlyLabel: 'Day 6: The Cross — love laid down for us'),
      ReadingPlanStep(stepIndex: 6, referenceList: const ['Luke 24', 'Matthew 28'], friendlyLabel: 'Day 7: Resurrection and Commission — He is risen!'),
    ];
    return ReadingPlan(
      planId: 'plan_story_of_jesus_7',
      title: 'The Story of Jesus (Highlights)',
      subtitle: 'Seven days in the Gospels',
      description: 'Key moments from Jesus’ life — simple daily readings that point to hope.',
      days: days,
    );
  }
}
