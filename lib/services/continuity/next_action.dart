import '../../data/connected/connected_catalog.dart';
import '../../models/connected/destination.dart';
import '../../models/connected/passage_reference.dart';
import '../../models/questline.dart';

class NextAction {
  final String title, reason;
  final ConnectedDestination destination;
  const NextAction(this.title, this.reason, this.destination);
}

/// Values copied from existing state. No callbacks, provider or storage access.
class ContinuitySnapshot {
  final QuestlineProgressView? activeJourney;
  final Set<String> completedJourneys, discoveries, learned, remembered;
  final PassageReference? recentReading, planReading;
  final String? planTitle;
  const ContinuitySnapshot(
      {this.activeJourney,
      this.completedJourneys = const {},
      this.discoveries = const {},
      this.learned = const {},
      this.remembered = const {},
      this.recentReading,
      this.planReading,
      this.planTitle});
}

class NextActionGuidance {
  final ConnectedCatalog catalog;
  NextActionGuidance([ConnectedCatalog? catalog])
      : catalog = catalog ?? ConnectedCatalog.current;
  NextAction resolve(ContinuitySnapshot s,
      {PassageReference? passage,
      bool learning = false,
      String? finishedJourney}) {
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
}
