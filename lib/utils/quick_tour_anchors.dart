import 'package:flutter/widgets.dart';

/// Global keys used to anchor the Quick Tour highlight rectangles.
/// These are intentionally static so both HomeScreen and MainNavigation
/// can reference the same instances.
class QuickTourAnchors {
  static final GlobalKey verseCardKey = GlobalKey(debugLabel: 'qt_verse');
  static final GlobalKey tonightsQuestKey = GlobalKey(debugLabel: 'qt_quest');
  static final GlobalKey bibleNavKey = GlobalKey(debugLabel: 'qt_bible');
  static final GlobalKey profileNavKey = GlobalKey(debugLabel: 'qt_profile');
}
