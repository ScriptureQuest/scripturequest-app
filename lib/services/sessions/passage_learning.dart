import '../../data/connected/connected_catalog.dart';
import '../../data/activities/activity_catalog.dart';
import '../../models/connected/passage_reference.dart';
import '../chapter_quiz_service.dart';

enum OpportunityState { available, completed, pending, optional }

class LearningOpportunity {
  final String title, detail, route;
  final OpportunityState state;
  const LearningOpportunity(this.title, this.detail, this.route, this.state);
  String get status => switch (state) {
        OpportunityState.available => 'Not yet completed',
        OpportunityState.completed => 'Completed · optional replay',
        OpportunityState.pending => 'Completion needs delivery · retry',
        OpportunityState.optional => 'Optional exploration',
      };
}

/// Catalog/read-state projection. It cannot grant rewards or change history.
class PassageLearning {
  final PassageReference passage;
  final List<LearningOpportunity> opportunities;
  final List<LearningOpportunity> connections;
  final List<LearningOpportunity> remembering;
  final List<LearningOpportunity> journeys;
  const PassageLearning(this.passage, this.opportunities, this.connections,
      this.remembering, this.journeys);
  bool get caughtUp =>
      opportunities.isNotEmpty &&
      opportunities.every((o) => o.state == OpportunityState.completed);
  static PassageLearning build(
    PassageReference p, {
    ConnectedCatalog? catalog,
    Set<String> learned = const {},
    Set<String> quizzes = const {},
    Map<String, dynamic> activities = const {},
    Set<String> remembered = const {},
    Set<String> earnedDiscoveries = const {},
  }) {
    final c = catalog ?? ConnectedCatalog.current;
    final opportunities = <LearningOpportunity>[];
    final quiz = ChapterQuizService.getQuizForChapter(p.book, p.chapter);
    if (quiz != null)
      opportunities.add(LearningOpportunity(
          'Chapter learning',
          'Quick, Standard or Deep · reflections are optional and ungraded.',
          Uri(
                  path: '/chapter-quiz',
                  queryParameters: {'book': p.book, 'chapter': '${p.chapter}'})
              .toString(),
          quizzes.contains(p.chapterKey)
              ? OpportunityState.completed
              : OpportunityState.available));
    for (final d in c.forPassage(p)) {
      opportunities.add(LearningOpportunity(
          'Find it in the Passage · ${d.title}',
          'Locate the evidence in Scripture.',
          '/find-passage/${d.id}',
          learned.contains(d.id)
              ? OpportunityState.completed
              : OpportunityState.available));
    }
    for (final a in ActivityCatalog.forPassage(p)) {
      final record = activities[a.id] as Map?;
      opportunities.add(LearningOpportunity(
          '${a.family} · ${a.title}',
          '${a.words.length} passage words · completion records the activity, not understanding.',
          a.route,
          record == null
              ? OpportunityState.available
              : record['pending'] == true
                  ? OpportunityState.pending
                  : OpportunityState.completed));
    }
    final connections = <LearningOpportunity>[
      for (final link in c.connections.where(
          (l) => PassageReference.tryParse(l.from)?.sameChapter(p) == true))
        LearningOpportunity(
            '${link.from} → ${link.to}',
            '${link.kind} · ${link.explanation}',
            PassageReference.tryParse(link.to)!.destination.route,
            OpportunityState.optional),
      for (final d in c.forPassage(p))
        LearningOpportunity(
            'Codex — Discoveries · ${d.title}',
            earnedDiscoveries.contains(d.id)
                ? 'Discovery kept · revisit its Scripture and context.'
                : 'Explore its Scripture and context; opening this does not earn a discovery.',
            '/discoveries/${d.id}',
            OpportunityState.optional),
    ];
    final remembering = <LearningOpportunity>[
      for (final d in c.forPassage(p))
        LearningOpportunity(
            'Remember ${d.memoryKey.replaceAll(':', ' ')}',
            remembered.contains(d.memoryKey)
                ? 'Earlier practice is kept. Independent recall remains separate.'
                : 'Choose these words to practice at your own pace.',
            Uri(
                path: '/memorization-practice',
                queryParameters: {'key': d.memoryKey}).toString(),
            OpportunityState.optional),
    ];
    return PassageLearning(
        p,
        List.unmodifiable(opportunities),
        List.unmodifiable(connections),
        List.unmodifiable(remembering),
        List.unmodifiable([
          for (final j in c.definitions.where((j) =>
              c.journeyIds.contains(j.id) &&
              j.steps.any((step) => c.passage(step)?.sameChapter(p) == true)))
            LearningOpportunity(j.title, c.purpose(j.id), '/journeys/${j.id}',
                OpportunityState.optional),
        ]));
  }
}
