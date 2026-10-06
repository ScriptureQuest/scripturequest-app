import 'package:flutter_test/flutter_test.dart';
import 'package:level_up_your_faith/services/continuity/next_action.dart';
import 'package:level_up_your_faith/services/sessions/passage_learning.dart';
import 'package:level_up_your_faith/services/sessions/session_return.dart';
import 'package:level_up_your_faith/models/connected/passage_reference.dart';
import 'package:level_up_your_faith/data/activities/activity_catalog.dart';

void main() {
  final guidance = NextActionGuidance();
  const john = PassageReference('John', 3);
  test('Today resumes reading while passage Learn can recommend evidence', () {
    const state = ContinuitySnapshot(recentReading: john);
    expect(
        guidance
            .resolve(state, context: SessionContext.today)
            .destination
            .route,
        john.destination.route);
    expect(
        guidance
            .resolve(state,
                passage: john, context: SessionContext.passageLearning)
            .destination
            .route,
        startsWith('/find-passage/'));
  });
  test('selected plan precedes recent optional activities on Today', () {
    const s = ContinuitySnapshot(
        recentReading: john,
        planReading: PassageReference('Romans', 8),
        planTitle: 'My plan');
    final a = guidance.resolve(s, context: SessionContext.today);
    expect(a.destination.route, '/reading-plans');
    expect(a.title, contains('My plan'));
    expect(
        guidance
            .resolve(s, passage: john, context: SessionContext.readingResult)
            .destination
            .route,
        startsWith('/find-passage/'));
  });
  test(
      'same-day stop permits revisit; older return resumes without learning debt',
      () {
    final now = DateTime(2026, 10, 6, 12);
    final s = ContinuitySnapshot(
        recentReading: john, returnPoint: SessionReturn('Romans 8', now));
    final stopped =
        guidance.resolve(s, context: SessionContext.today, now: now);
    expect(stopped.optionalReplay, true);
    expect(stopped.destination.route,
        const PassageReference('Romans', 8).destination.route);
    expect(
        guidance
            .resolve(s,
                context: SessionContext.today,
                now: now.add(const Duration(days: 1)))
            .destination
            .route,
        const PassageReference('Romans', 8).destination.route);
  });
  test(
      'reading result offers a passage follow-up; learning result offers exploration',
      () {
    final reading = guidance.resolve(const ContinuitySnapshot(),
        passage: john, context: SessionContext.readingResult);
    final learned = guidance.resolve(const ContinuitySnapshot(),
        passage: john, context: SessionContext.learningResult);
    expect(reading.destination.route, startsWith('/find-passage'));
    expect(learned.destination.route, '/learn?ref=John+3');
    expect(learned.optionalReplay, true);
    expect(learned.reason, isNot(contains('incomplete')));
  });
  test(
      'completed and replayed study does not demand the next unfinished activity',
      () {
    for (final state in [
      const ContinuitySnapshot(),
      ContinuitySnapshot(learned: {'questions'}, quizzes: {john.chapterKey})
    ]) {
      final a = guidance.resolve(state,
          passage: john, context: SessionContext.learningResult);
      expect(a.destination.route, '/learn?ref=John+3');
      expect(a.optionalReplay, true);
    }
  });
  test('pending delivery stays actionable even at a learning result', () {
    final activity = ActivityCatalog.forPassage(john).first;
    final s = ContinuitySnapshot(activities: {
      activity.id: {'pending': true}
    });
    for (final context in [
      SessionContext.readingResult,
      SessionContext.learningResult,
      SessionContext.passageLearning
    ]) {
      final a = guidance.resolve(s, passage: john, context: context);
      expect(a.destination.route, activity.route);
      expect(a.reason, contains('Finish saving'));
      expect(a.optionalReplay, false);
    }
  });
  test(
      'exhausted supported passage retains optional Scripture and all replay routes',
      () {
    final initial = PassageLearning.build(john);
    final learnedIds = initial.opportunities
        .where((o) => o.route.startsWith('/find-passage/'))
        .map((o) => o.route.split('/').last)
        .toSet();
    final activity = {
      for (final a in ActivityCatalog.forPassage(john)) a.id: {'pending': false}
    };
    final s = ContinuitySnapshot(
        learned: learnedIds, quizzes: {john.chapterKey}, activities: activity);
    final a = guidance.resolve(s,
        passage: john, context: SessionContext.readingResult);
    expect(a.destination.route, john.destination.route);
    expect(a.optionalReplay, true);
    final view = PassageLearning.build(john,
        learned: learnedIds, quizzes: s.quizzes, activities: activity);
    expect(view.opportunities.length, initial.opportunities.length);
    expect(
        view.opportunities.every((o) => o.state == OpportunityState.completed),
        true);
    expect(view.connections, isNotEmpty);
    expect(view.remembering, isNotEmpty);
    expect(view.journeys, isNotEmpty);
  });
  test(
      'unsupported passage offers Scripture without invented learning or an obligation',
      () {
    const p = PassageReference('Genesis', 1);
    final a = guidance.resolve(const ContinuitySnapshot(),
        passage: p, context: SessionContext.readingResult);
    expect(a.destination.route, p.destination.route);
    expect(a.optionalReplay, true);
    expect(PassageLearning.build(p).opportunities, isEmpty);
    expect(OpportunityState.available, isNot(OpportunityState.completed));
    expect(
        PassageLearning.build(john)
            .opportunities
            .every((o) => !o.status.contains('Not yet')),
        true);
  });
}
