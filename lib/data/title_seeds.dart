import 'package:level_up_your_faith/models/title_model.dart';

/// Simple v1.0 title seeds with unlock conditions.
class TitleSeedsV1 {
  static List<TitleModel> list() => const [
        TitleModel(
          id: 'pilgrim',
          name: 'Pilgrim',
          description: 'A traveler beginning the sacred journey.',
          unlockAchievementId: 'first_step_taken',
        ),
        TitleModel(
          id: 'seeker_of_peace',
          name: 'Seeker of Peace',
          description: 'One who found calm in the storm.',
          unlockQuestlineId: 'peace_in_the_storm',
        ),
        TitleModel(
          id: 'disciple_in_training',
          name: 'Disciple in Training',
          description: 'Steady footsteps in daily pursuit of Christ.',
          unlockAchievementId: 'daily_seeker',
        ),

        // ===== New Titles v1.0 extension =====
        TitleModel(
          id: 'child_of_light',
          name: 'Child of Light',
          description: 'Walking in the light of God’s Word.',
          unlockAchievementId: 'read_chapters_5',
        ),
        TitleModel(
          id: 'word_explorer',
          name: 'Word Explorer',
          description: 'Curious and steady in Scripture.',
          unlockAchievementId: 'read_chapters_10',
        ),
        TitleModel(
          id: 'daily_seeker_title',
          name: 'Daily Seeker',
          description: 'Three days strong — keep the rhythm.',
          unlockAchievementId: 'bible_streak_3',
        ),
        TitleModel(
          id: 'verse_guardian',
          name: 'Verse Guardian',
          description: 'Keeps verses close to heart.',
          unlockAchievementId: 'memory_builder_3',
        ),
        TitleModel(
          id: 'playful_learner',
          name: 'Playful Learner',
          description: 'Learning with joy through games.',
          unlockAchievementId: 'learning_games_5',
        ),
        TitleModel(
          id: 'quiet_heart',
          name: 'Quiet Heart',
          description: 'Gently reflecting with the Lord.',
          unlockAchievementId: 'quiet_reflections_5',
        ),
        TitleModel(
          id: 'scripture_apprentice',
          name: 'Scripture Apprentice',
          description: 'Completed a full questline journey.',
          unlockAchievementId: 'questline_completed_1',
        ),
        TitleModel(
          id: 'faith_walker',
          name: 'Faith Walker',
          description: 'Three full questlines behind you. Beautiful pace.',
          unlockAchievementId: 'questlines_completed_3',
        ),
        TitleModel(
          id: 'night_scholar',
          name: 'Night Scholar',
          description: 'Faithful in nightly practice.',
          unlockAchievementId: 'night_scholar_5',
        ),
        TitleModel(
          id: 'joyful_reader',
          name: 'Joyful Reader',
          description: 'Reading with joy and beginning Psalms of Peace.',
          unlockAchievementId: 'joyful_reader',
        ),
      ];
}
