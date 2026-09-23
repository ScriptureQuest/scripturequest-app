import '../../models/questline.dart';
import '../../models/connected/passage_reference.dart';
import '../exploration/catalog.dart';
import 'journey_definitions.dart';
import 'journey_editorial.dart';

class JourneyPresentation {
  final String id, scene;
  const JourneyPresentation(this.id, this.scene);
}

/// One connected relationship boundary over existing content authorities.
/// No stored state, enrollment, reward or completion logic belongs here.
class ConnectedCatalog {
  static const presentations = [
    JourneyPresentation('onboarding_getting_started', 'night'),
    JourneyPresentation('knowing_jesus', 'light'),
    JourneyPresentation('psalms_of_peace', 'peace'),
  ];
  static final current = ConnectedCatalog();
  final List<Questline> definitions;
  final List<Discovery> guides;
  final List<ScriptureConnection> connections;
  final List<JourneyPresentation> curated;
  ConnectedCatalog(
      {List<Questline>? definitions,
      this.guides = discoveries,
      this.connections = scriptureConnections,
      this.curated = presentations})
      : definitions = definitions ?? journeyDefinitions();
  Set<String> get journeyIds => curated.map((e) => e.id).toSet();
  Questline journey(String id) => definitions.firstWhere((d) => d.id == id);
  String scene(String id) =>
      curated.where((e) => e.id == id).firstOrNull?.scene ?? 'night';
  String purpose(String id) =>
      JourneyEditorial.purposes[id] ?? journey(id).description;
  String? orientation(String journeyId, String stepId) =>
      journey(journeyId).steps.any((s) => s.id == stepId)
          ? JourneyEditorial.orientations['$journeyId/$stepId']
          : null;
  PassageReference? passage(QuestlineStep? step) =>
      PassageReference.tryParse(JourneyEditorial.reference(step));
  Iterable<Discovery> forPassage(PassageReference p) => guides
      .where((d) => PassageReference.tryParse(d.reference)!.sameChapter(p));
  Iterable<Discovery> forJourney(String id) =>
      guides.where((d) => journey(id).steps.any((s) =>
          passage(s)?.sameChapter(PassageReference.tryParse(d.reference)!) ==
          true));
  Iterable<Questline> journeysFor(Discovery d) => definitions.where((j) =>
      journeyIds.contains(j.id) && forJourney(j.id).any((e) => e.id == d.id));
  Iterable<ScriptureConnection> connectionsFor(Discovery d) =>
      connections.where((c) =>
          PassageReference.tryParse(c.from)
              ?.sameChapter(PassageReference.tryParse(d.reference)!) ==
          true);
  // Existing surfaced chapter challenges; content remains owned by ChapterQuizService.
  static const chapterLearning = [
    PassageReference('John', 3),
    PassageReference('Romans', 8),
    PassageReference('Psalms', 23)
  ];
  List<String> validate() {
    final errors = <String>[];
    void unique(Iterable<String> ids, String kind) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) errors.add('Duplicate $kind: $id');
      }
    }

    unique(definitions.map((d) => d.id), 'journey');
    unique(guides.map((d) => d.id), 'discovery');
    unique(connections.map((d) => d.id), 'connection');
    unique(curated.map((d) => d.id), 'presentation');
    for (final p in curated) {
      if (!definitions.any((d) => d.id == p.id))
        errors.add('Missing journey: ${p.id}');
    }
    for (final j in definitions) {
      unique(j.steps.map((s) => s.id), 'step in ${j.id}');
      for (final s in j.steps) {
        if (JourneyEditorial.reference(s) != null && passage(s) == null)
          errors.add('Invalid passage: ${j.id}/${s.id}');
      }
    }
    for (final d in guides) {
      if (PassageReference.tryParse(d.reference) == null)
        errors.add('Invalid discovery: ${d.id}');
      if (!definitions.any((j) => j.id == d.journey))
        errors.add('Missing discovery journey: ${d.id}');
    }
    for (final c in connections) {
      if (PassageReference.tryParse(c.from) == null ||
          PassageReference.tryParse(c.to) == null)
        errors.add('Invalid connection: ${c.id}');
    }
    return errors;
  }
}
