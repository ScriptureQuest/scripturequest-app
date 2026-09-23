import 'package:level_up_your_faith/models/questline.dart';

/// Editorial layer over the original stable journey/step identifiers.
class JourneyEditorial {
  static const purposes = {
    'onboarding_getting_started': 'Where can I begin with the Bible?',
    'knowing_jesus': 'Who is Jesus, and what does John invite us to see?',
    'psalms_of_peace':
        'How do the Psalms speak of trust when life feels uncertain?',
  };
  static const orientations = {
    'onboarding_getting_started/s1':
        'Read John 3 around verse 16. Notice how love, belief, and life are connected in the passage.',
    'onboarding_getting_started/s2':
        'Read Romans 8 around verse 28. Notice the wider setting of hope, suffering, and God’s love.',
    'knowing_jesus/k1':
        'John introduces Jesus as the Word and describes people meeting him. Notice the different names and descriptions they use.',
    'knowing_jesus/k3':
        'Listen to Jesus’ conversation with Nicodemus. What questions does Nicodemus bring?',
    'psalms_of_peace/pp1':
        'Read Psalm 4, ending with verse 8. Notice the movement from calling for help to resting in trust.',
    'psalms_of_peace/pp2':
        'Follow the images in Psalm 23: pasture, path, valley, table, and dwelling. What changes along the way? What remains?',
    'psalms_of_peace/pp3':
        'Read Psalm 46 around verse 1. Notice the contrast between upheaval and refuge.',
    'psalms_of_peace/pp4':
        'Read Psalm 91 around verses 1–2. Notice its language of shelter and trust. Keep questions you want to explore.',
    'psalms_of_peace/pp5':
        'Read Psalm 121 around verses 1–2. Notice how the psalm asks where help comes from, then responds.',
  };
  static String? reference(QuestlineStep? step) {
    if (step == null) return null;
    for (final prefix in ['tpl:read:', 'tpl:readChapter:']) {
      if (step.questId.startsWith(prefix))
        return step.questId.substring(prefix.length);
    }
    return null;
  }

  static bool reflection(QuestlineStep step) =>
      step.questId.startsWith('tpl:reflection:');
  static String route(String reference) =>
      Uri(path: '/verses', queryParameters: {'ref': reference}).toString();
}
