/// Authored reading guides. Explanations are commentary, never additional Bible text.
class Discovery {
  final String id, title, book, journey, scene, explanation, prompt, memoryKey;
  final int chapter, answerVerse;
  final String evidence;
  const Discovery(
      this.id,
      this.title,
      this.book,
      this.chapter,
      this.journey,
      this.scene,
      this.explanation,
      this.prompt,
      this.answerVerse,
      this.evidence,
      this.memoryKey);
  String get reference => '$book $chapter';
}

class ScriptureConnection {
  final String id, kind, from, to, explanation;
  const ScriptureConnection(
      this.id, this.kind, this.from, this.to, this.explanation);
}

const discoveries = <Discovery>[
  Discovery(
      'shepherd',
      'The Shepherd’s Care',
      'Psalms',
      23,
      'psalms_of_peace',
      'peace',
      'Psalm 23 moves from pasture and paths to a dark valley, a prepared table, and dwelling with the Lord. Notice how the setting changes while the language of care continues. Verse 4 addresses the Lord directly.',
      'Find the verse where the speaker says the Lord is with him in the valley.',
      4,
      'thou art with me',
      'Psalms:23:1'),
  Discovery(
      'word',
      'The Word Among Us',
      'John',
      1,
      'knowing_jesus',
      'light',
      'John opens with the Word, life, and light. Verse 14 speaks of the Word becoming flesh. Later, witnesses describe whom they have encountered. Read these descriptions in the chapter rather than treating them as isolated labels.',
      'Find the verse that says the Word was made flesh and dwelt among us.',
      14,
      'the Word was made flesh',
      'John:1:14'),
  Discovery(
      'questions',
      'A Conversation at Night',
      'John',
      3,
      'onboarding_getting_started',
      'night',
      'Nicodemus brings questions to Jesus. Follow the exchange: Nicodemus asks about birth in verse 4 and asks how these things can be in verse 9. The chapter continues with Jesus’ answer. Questions can be a starting point for careful reading.',
      'Find Nicodemus asking, “How can these things be?”',
      9,
      'How can these things be',
      'John:3:16'),
  Discovery(
      'refuge',
      'Refuge Amid Upheaval',
      'Psalms',
      46,
      'psalms_of_peace',
      'peace',
      'Psalm 46 places language of refuge alongside images of a shaking earth, waters, and nations. Notice its repeated affirmation in verses 7 and 11. This is a poem to read as a whole, not a promise that difficulty will never come.',
      'Find the opening verse describing God as a refuge and strength.',
      1,
      'refuge and strength',
      'Psalms:46:1'),
];
const scriptureConnections = <ScriptureConnection>[
  ScriptureConnection('voice', 'Explicit quotation', 'John 1:23', 'Isaiah 40:3',
      'John identifies himself using the voice-in-the-wilderness passage and names the prophet Isaiah (Esaias in the KJV). Read Isaiah’s surrounding passage as well as John’s use of it.'),
  ScriptureConnection(
      'storm',
      'Parallel accounts',
      'Mark 4:35-41',
      'Luke 8:22-25',
      'Both accounts describe Jesus and his disciples crossing the water, a storm, and Jesus calming it. Compare what each writer includes. Do not assume every difference must be filled in from the other account.'),
  ScriptureConnection(
      'shepherd-image',
      'Recurring imagery',
      'Psalms 23:1',
      'John 10:11',
      'Psalm 23 describes the Lord as the speaker’s shepherd. In John 10 Jesus calls himself the good shepherd. Explore how shepherd language functions in each passage. This card identifies shared imagery, not an explicit quotation.'),
  ScriptureConnection(
      'peace-theme',
      'Editorial thematic connection',
      'Psalms 46:1',
      'Philippians 4:6-7',
      'These passages offer different settings for considering refuge, prayer, and peace. This is a suggested reading pairing, not a claim that one passage quotes or directly interprets the other.'),
];
Discovery discoveryById(String id) => discoveries.firstWhere((d) => d.id == id);
