import '../../providers/app_provider.dart';
import '../../models/connected/passage_reference.dart';
import 'next_action.dart';

/// Read adapter only. The resolver cannot access the provider or any writers.
class ContinuityReader {
  static Future<ContinuitySnapshot> read(AppProvider app) async {
    if (app.currentUser == null) return const ContinuitySnapshot();
    final history = await app.journeyHistory();
    final state = app
        .explorationState; // Corrupt history surfaces an error, never a reset.
    return ContinuitySnapshot(
        activeJourney: app.focusedJourney,
        completedJourneys: Set.unmodifiable(history
            .where((v) => v.progress.isCompleted)
            .map((v) => v.questline.id)),
        discoveries: Set.unmodifiable(app.discoveryRecords.keys),
        learned:
            Set.unmodifiable((state['learning'] as Map).keys.cast<String>()),
        remembered: Set.unmodifiable({
          ...app.favoriteVerseKeys,
          ...(state['memory'] as Map).keys.cast<String>()
        }),
        recentReading: PassageReference.tryParse(app.lastBibleReference),
        planReading: PassageReference.tryParse(
            app.getFirstUnreadReferenceForCurrentStep()),
        planTitle: app.activeReadingPlan?.title);
  }
}
