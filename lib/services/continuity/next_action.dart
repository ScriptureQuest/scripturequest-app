import '../sessions/passage_learning.dart';
import '../sessions/session_return.dart';
import '../../data/connected/connected_catalog.dart';
import '../../models/connected/destination.dart';
import '../../models/connected/passage_reference.dart';
import '../../models/questline.dart';

enum SessionContext {
  today,
  journey,
  freeReading,
  passageLearning,
  readingResult,
  learningResult
}

class NextAction {
  final String title, reason;
  final ConnectedDestination destination;
  final bool optionalReplay;
  const NextAction(this.title, this.reason, this.destination,
      {this.optionalReplay = false});
}

/// Values copied from existing state. No callbacks, provider or storage access.
class ContinuitySnapshot {
  final QuestlineProgressView? activeJourney;
  final Set<String> completedJourneys, discoveries, learned, remembered;
  final PassageReference? recentReading, planReading;
  final String? planTitle;
  final Set<String> quizzes;
  final Map<String, dynamic> activities;
  final SessionReturn? returnPoint;
  const ContinuitySnapshot(
      {this.activeJourney,
      this.completedJourneys = const {},
      this.discoveries = const {},
      this.learned = const {},
      this.remembered = const {},
      this.recentReading,
      this.planReading,
      this.planTitle,
      this.quizzes = const {},
      this.activities = const {},
      this.returnPoint});
}

class NextActionGuidance {
  final ConnectedCatalog catalog;
  NextActionGuidance([ConnectedCatalog? catalog])
      : catalog = catalog ?? ConnectedCatalog.current;
  NextAction resolve(ContinuitySnapshot s,
      {PassageReference? passage,
      bool learning = false,
      String? finishedJourney,
      SessionContext? context,
      DateTime? now}) {
    // Explicit session context is used by V2 screens. Existing callers retain
    // their established navigation contract until they opt into the context.
    if (context != null)
      return _contextual(
          s, passage, context, finishedJourney, now ?? DateTime.now());
    final j = s.activeJourney;
    if (j != null &&
        !j.progress.isCompleted &&
        j.questline.id != finishedJourney) {
      final ref = catalog.passage(j.currentStep);
      return NextAction(
          'Continue ${j.questline.title}',
          ref == null
              ? 'Your next step is an optional response. Continue with or without writing.'
              : 'Next step · ${ref.label}. Your earlier progress is kept.',
          ConnectedDestination('/journeys/${j.questline.id}'));
    }
    if (s.planReading != null)
      return NextAction(
          'Continue ${s.planTitle ?? 'your reading plan'}',
          'Next reading · ${s.planReading!.label}. Your plan keeps its own schedule.',
          const ConnectedDestination('/reading-plans'));
    final recent = passage ?? s.recentReading;
    if (recent != null) {
      final related = catalog.forPassage(recent).where(
          (d) => s.discoveries.contains(d.id) && !s.learned.contains(d.id));
      if (related.isNotEmpty) {
        final d = related.first;
        return NextAction(
            'Look closer · ${d.title}',
            '${d.reference} · Find the evidence in the Scripture you explored.',
            ConnectedDestination('/find-passage/${d.id}'));
      }
    }
    if (learning) {
      final pending = catalog.guides.where(
          (d) => s.discoveries.contains(d.id) && !s.learned.contains(d.id));
      if (pending.isNotEmpty) {
        final d = pending.first;
        return NextAction(
            'Look closer · ${d.title}',
            '${d.reference} · Continue learning from your reading.',
            ConnectedDestination('/find-passage/${d.id}'));
      }
      if (s.remembered.isNotEmpty)
        return const NextAction(
            'Return to Remembered Scripture',
            'Choose words you want to practice again. Your earlier recall is kept.',
            ConnectedDestination('/remembered'));
    }
    if (finishedJourney != null ||
        (recent == null && s.completedJourneys.isNotEmpty)) {
      final next = catalog.curated.where((p) =>
          p.id != finishedJourney && !s.completedJourneys.contains(p.id));
      if (next.isNotEmpty) {
        final j = catalog.journey(next.first.id);
        return NextAction('Explore ${j.title}', catalog.purpose(j.id),
            ConnectedDestination('/journeys/${j.id}'));
      }
      return const NextAction(
          'Revisit your Scripture story',
          'Your Journeys are kept. Choose a passage to explore again.',
          ConnectedDestination('/journey-board'));
    }
    if (recent != null)
      return NextAction(
          'Return to ${recent.label}',
          'Read freely, continue to the next chapter, or follow a connection. No Journey is required.',
          recent.destination);
    if (s.discoveries.isNotEmpty)
      return const NextAction(
          'Revisit your discoveries',
          'Return to the Scripture behind what you have kept.',
          ConnectedDestination('/discoveries'));
    final first = catalog.journey(catalog.curated.first.id);
    return NextAction('Begin ${first.title}', catalog.purpose(first.id),
        ConnectedDestination('/journeys/${first.id}'));
  }

  NextAction _contextual(ContinuitySnapshot s, PassageReference? passage,
      SessionContext context, String? finishedJourney, DateTime now) {
    if (context == SessionContext.today &&
        s.returnPoint?.isToday(now) == true) {
      final p = PassageReference.tryParse(s.returnPoint!.reference)!;
      return NextAction(
          'Return to ${p.label}',
          'Your session is saved. You can stop here, or revisit when you are ready.',
          p.destination,
          optionalReplay: true);
    }
    if (context == SessionContext.today || context == SessionContext.journey) {
      final j = s.activeJourney;
      if (j != null &&
          !j.progress.isCompleted &&
          j.questline.id != finishedJourney) {
        final p = catalog.passage(j.currentStep);
        return NextAction(
            'Continue ${j.questline.title}',
            p == null
                ? 'Your next step is an optional response. Continue with or without writing.'
                : '${p.label} · ${catalog.orientation(j.questline.id, j.currentStep!.id) ?? catalog.purpose(j.questline.id)}',
            ConnectedDestination('/journeys/${j.questline.id}'));
      }
    }
    // Entry guidance resumes reading intentions; optional catalog work never
    // competes with a chosen Journey, plan or return point on Today.
    if (context == SessionContext.today || context == SessionContext.journey) {
      if (s.planReading != null) {
        return NextAction(
            'Continue ${s.planTitle ?? 'your reading plan'}',
            'Next reading · ${s.planReading!.label}',
            const ConnectedDestination('/reading-plans'));
      }
      final resume = PassageReference.tryParse(s.returnPoint?.reference) ??
          s.recentReading;
      if (resume != null && finishedJourney == null) {
        return NextAction('Return to ${resume.label}',
            'Continue reading at your pace.', resume.destination,
            optionalReplay: s.returnPoint != null);
      }
      return resolve(s, finishedJourney: finishedJourney);
    }
    final recent = passage ??
        s.recentReading ??
        PassageReference.tryParse(s.returnPoint?.reference);
    if (recent != null) {
      final view = PassageLearning.build(recent,
          catalog: catalog,
          learned: s.learned,
          quizzes: s.quizzes,
          activities: s.activities,
          remembered: s.remembered,
          earnedDiscoveries: s.discoveries);
      // Evidence comes first after reading when it is available; chapter learning
      // follows, then passage games. Pending deliveries always take precedence.
      final pending =
          view.opportunities.where((o) => o.state == OpportunityState.pending);
      final available = view.opportunities
          .where((o) => o.state == OpportunityState.available)
          .toList();
      available.sort((a, b) => (a.route.startsWith('/find-passage') ? 0 : 1)
          .compareTo(b.route.startsWith('/find-passage') ? 0 : 1));
      if (context == SessionContext.learningResult && pending.isEmpty) {
        return NextAction(
            'Explore ${recent.label}',
            'More study is here whenever you want it.',
            ConnectedDestination(
                Uri(path: '/learn', queryParameters: {'ref': recent.label})
                    .toString()),
            optionalReplay: true);
      }
      final next = pending.isNotEmpty ? pending.first : available.firstOrNull;
      if (next != null)
        return NextAction(
            next.title,
            '${recent.label} · ${next.state == OpportunityState.pending ? 'Finish saving your earlier completion.' : next.route.startsWith('/find-passage') ? 'Find evidence in the passage.' : next.route.startsWith('/chapter-quiz') ? 'Consider questions about what you read.' : 'Work with words from the passage.'}',
            ConnectedDestination(next.route));
      if (context == SessionContext.passageLearning ||
          context == SessionContext.freeReading ||
          context == SessionContext.readingResult) {
        return NextAction(
            'Revisit ${recent.label}',
            view.opportunities.isEmpty
                ? 'No authored challenges are available for this chapter yet. Read, highlight or reflect at your own pace.'
                : 'Return to the passage, or explore its connections at your pace.',
            recent.destination,
            optionalReplay: true);
      }
    }
    // Reuse the established new-user/plan/finished-Journey fallbacks.
    return resolve(s, passage: passage, finishedJourney: finishedJourney);
  }
}
