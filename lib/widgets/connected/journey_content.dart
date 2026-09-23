import '../../data/connected/journey_editorial.dart';
import '../../models/questline.dart';

/// Compatibility facade; connected editorial content has one owner.
class JourneyContent {
  static const purposes = JourneyEditorial.purposes;
  static String? reference(QuestlineStep? step) =>
      JourneyEditorial.reference(step);
  static bool reflection(QuestlineStep step) =>
      JourneyEditorial.reflection(step);
  static String route(String ref) => JourneyEditorial.route(ref);
}
