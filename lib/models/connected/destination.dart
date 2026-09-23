/// Stable routes are retained. Ownership describes the destination, while push
/// preserves the caller's actual stack (including cross-tab reading context).
enum ProductTab { today, journeys, bible, learn, you }

class ConnectedDestination {
  final String route;
  const ConnectedDestination(this.route);
  ProductTab get owner => ownerOf(route);
  static ProductTab ownerOf(String route) {
    final path = Uri.parse(route).path;
    if (path == '/' || path.startsWith('/tasks')) return ProductTab.today;
    if (path.startsWith('/journeys') ||
        path.startsWith('/quests') ||
        path.startsWith('/questline') ||
        path.startsWith('/reading-plans')) return ProductTab.journeys;
    if (path.startsWith('/bible') ||
        path.startsWith('/verses') ||
        path.startsWith('/scripture')) return ProductTab.bible;
    if (path == '/learn' ||
        path.startsWith('/find-passage') ||
        path.startsWith('/play-learn') ||
        path.contains('game') ||
        path.contains('quiz') ||
        path.contains('memorization') ||
        path.contains('scramble') ||
        path.contains('parables')) return ProductTab.learn;
    return ProductTab.you;
  }
}
