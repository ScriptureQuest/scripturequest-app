import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:level_up_your_faith/models/verse_model.dart';
import 'package:level_up_your_faith/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class VerseService {
  static const String _storageKey = 'verses';
  final StorageService _storage;
  final _uuid = const Uuid();

  VerseService(this._storage);

  Future<void> _initializeSampleData() async {
    final verses = _getSampleVerses();
    final jsonList = verses.map((v) => v.toJson()).toList();
    await _storage.save(_storageKey, jsonEncode(jsonList));
  }

  Future<List<VerseModel>> getAllVerses() async {
    try {
      final jsonString = _storage.getString(_storageKey);
      if (jsonString == null) {
        await _initializeSampleData();
        return getAllVerses();
      }
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => VerseModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading verses: $e');
      return [];
    }
  }

  Future<List<VerseModel>> getVersesByCategory(String category) async {
    final verses = await getAllVerses();
    if (category == 'all') return verses;
    return verses.where((v) => v.category == category).toList();
  }

  Future<VerseModel?> getDailyVerse() async {
    final verses = await getAllVerses();
    if (verses.isEmpty) return null;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return verses[dayOfYear % verses.length];
  }

  Future<VerseModel?> getRandomVerse() async {
    final verses = await getAllVerses();
    if (verses.isEmpty) return null;
    verses.shuffle();
    return verses.first;
  }

  Future<VerseModel?> getVerseById(String id) async {
    final verses = await getAllVerses();
    try {
      return verses.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> completeVerse(String verseId) async {
    final verses = await getAllVerses();
    final index = verses.indexWhere((v) => v.id == verseId);
    if (index != -1) {
      verses[index] = verses[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _saveVerses(verses);
    }
  }

  Future<void> saveNote(String verseId, String note) async {
    final verses = await getAllVerses();
    final index = verses.indexWhere((v) => v.id == verseId);
    if (index != -1) {
      verses[index] = verses[index].copyWith(
        notes: note,
        updatedAt: DateTime.now(),
      );
      await _saveVerses(verses);
    }
  }

  Future<void> _saveVerses(List<VerseModel> verses) async {
    final jsonList = verses.map((v) => v.toJson()).toList();
    await _storage.save(_storageKey, jsonEncode(jsonList));
  }

  List<VerseModel> _getSampleVerses() {
    final now = DateTime.now();
    final verses = [
      {'ref': 'John 3:16', 'text': 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.', 'category': 'love', 'xp': 15, 'diff': 1},
      {'ref': 'Philippians 4:13', 'text': 'I can do all this through him who gives me strength.', 'category': 'strength', 'xp': 10, 'diff': 1},
      {'ref': 'Proverbs 3:5-6', 'text': 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.', 'category': 'faith', 'xp': 15, 'diff': 2},
      {'ref': 'Romans 8:28', 'text': 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.', 'category': 'faith', 'xp': 12, 'diff': 1},
      {'ref': 'Jeremiah 29:11', 'text': 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.', 'category': 'faith', 'xp': 12, 'diff': 1},
      {'ref': 'Psalm 23:1', 'text': 'The Lord is my shepherd, I lack nothing.', 'category': 'faith', 'xp': 8, 'diff': 1},
      {'ref': 'Matthew 6:33', 'text': 'But seek first his kingdom and his righteousness, and all these things will be given to you as well.', 'category': 'wisdom', 'xp': 12, 'diff': 1},
      {'ref': 'Isaiah 41:10', 'text': 'So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand.', 'category': 'courage', 'xp': 15, 'diff': 2},
      {'ref': 'Joshua 1:9', 'text': 'Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.', 'category': 'courage', 'xp': 15, 'diff': 2},
      {'ref': 'Psalm 46:1', 'text': 'God is our refuge and strength, an ever-present help in trouble.', 'category': 'strength', 'xp': 10, 'diff': 1},
      {'ref': 'Romans 12:2', 'text': 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God\'s will is—his good, pleasing and perfect will.', 'category': 'wisdom', 'xp': 18, 'diff': 2},
      {'ref': '1 Corinthians 13:4-5', 'text': 'Love is patient, love is kind. It does not envy, it does not boast, it is not proud. It does not dishonor others, it is not self-seeking, it is not easily angered, it keeps no record of wrongs.', 'category': 'love', 'xp': 18, 'diff': 3},
      {'ref': 'Galatians 5:22-23', 'text': 'But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control. Against such things there is no law.', 'category': 'wisdom', 'xp': 18, 'diff': 3},
      {'ref': 'Ephesians 2:8-9', 'text': 'For it is by grace you have been saved, through faith—and this is not from yourselves, it is the gift of God—not by works, so that no one can boast.', 'category': 'faith', 'xp': 15, 'diff': 2},
      {'ref': 'Psalm 119:105', 'text': 'Your word is a lamp for my feet, a light on my path.', 'category': 'wisdom', 'xp': 10, 'diff': 1},
      {'ref': 'Matthew 5:16', 'text': 'In the same way, let your light shine before others, that they may see your good deeds and glorify your Father in heaven.', 'category': 'wisdom', 'xp': 12, 'diff': 1},
      {'ref': 'Proverbs 16:3', 'text': 'Commit to the Lord whatever you do, and he will establish your plans.', 'category': 'wisdom', 'xp': 10, 'diff': 1},
      {'ref': '2 Timothy 1:7', 'text': 'For the Spirit God gave us does not make us timid, but gives us power, love and self-discipline.', 'category': 'courage', 'xp': 12, 'diff': 1},
      {'ref': 'Hebrews 11:1', 'text': 'Now faith is confidence in what we hope for and assurance about what we do not see.', 'category': 'faith', 'xp': 12, 'diff': 1},
      {'ref': 'James 1:2-3', 'text': 'Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds, because you know that the testing of your faith produces perseverance.', 'category': 'strength', 'xp': 15, 'diff': 2},
      {'ref': 'Psalm 91:1-2', 'text': 'Whoever dwells in the shelter of the Most High will rest in the shadow of the Almighty. I will say of the Lord, "He is my refuge and my fortress, my God, in whom I trust."', 'category': 'faith', 'xp': 15, 'diff': 2},
      {'ref': 'Matthew 11:28', 'text': 'Come to me, all you who are weary and burdened, and I will give you rest.', 'category': 'love', 'xp': 10, 'diff': 1},
      {'ref': '1 John 4:8', 'text': 'Whoever does not love does not know God, because God is love.', 'category': 'love', 'xp': 10, 'diff': 1},
      {'ref': 'Romans 5:8', 'text': 'But God demonstrates his own love for us in this: While we were still sinners, Christ died for us.', 'category': 'love', 'xp': 12, 'diff': 1},
      {'ref': 'Colossians 3:23', 'text': 'Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.', 'category': 'wisdom', 'xp': 12, 'diff': 1},
      {'ref': 'Psalm 27:1', 'text': 'The Lord is my light and my salvation—whom shall I fear? The Lord is the stronghold of my life—of whom shall I be afraid?', 'category': 'courage', 'xp': 12, 'diff': 1},
      {'ref': 'Proverbs 4:23', 'text': 'Above all else, guard your heart, for everything you do flows from it.', 'category': 'wisdom', 'xp': 10, 'diff': 1},
      {'ref': '1 Peter 5:7', 'text': 'Cast all your anxiety on him because he cares for you.', 'category': 'love', 'xp': 10, 'diff': 1},
      {'ref': 'Isaiah 40:31', 'text': 'But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.', 'category': 'strength', 'xp': 15, 'diff': 2},
      {'ref': 'Matthew 22:37-39', 'text': 'Jesus replied: "Love the Lord your God with all your heart and with all your soul and with all your mind." This is the first and greatest commandment. And the second is like it: "Love your neighbor as yourself."', 'category': 'love', 'xp': 18, 'diff': 3},
    ];

    return verses.map((v) => VerseModel(
      id: _uuid.v4(),
      reference: v['ref'] as String,
      text: v['text'] as String,
      category: v['category'] as String,
      xpReward: v['xp'] as int,
      difficulty: v['diff'] as int,
      createdAt: now,
      updatedAt: now,
    )).toList();
  }
}
