import 'package:shared_preferences/shared_preferences.dart';

class PodcastProgressService {
  static String _key(String bookId) => 'podcast_progress_$bookId';

  static Future<void> savePosition(String bookId, Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key(bookId), position.inMilliseconds);
  }

  static Future<Duration?> loadPosition(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_key(bookId));
    if (ms == null) return null;
    return Duration(milliseconds: ms);
  }

  static Future<Map<String, int>> loadAllPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, int>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith('podcast_progress_')) {
        final bookId = key.replaceFirst('podcast_progress_', '');
        final ms = prefs.getInt(key);
        if (ms != null) map[bookId] = ms;
      }
    }
    return map;
  }
}
