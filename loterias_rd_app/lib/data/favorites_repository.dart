import 'package:shared_preferences/shared_preferences.dart';

/// Simple repository for persisting favourite result identifiers.
class FavoritesRepository {
  static const String _key = 'favorite_ids';
  static const String _lotteryKey = 'favorite_lottery_ids';

  Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet();
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    await prefs.setStringList(_key, set.toList());
  }

  Future<bool> isFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.contains(id);
  }

  Future<Set<String>> getFavoriteLotteryIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_lotteryKey) ?? []).toSet();
  }

  Future<bool> toggleFavoriteLottery(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = (prefs.getStringList(_lotteryKey) ?? []).toSet();
    final isFavorite = favorites.contains(id);
    isFavorite ? favorites.remove(id) : favorites.add(id);
    await prefs.setStringList(_lotteryKey, favorites.toList()..sort());
    return !isFavorite;
  }
}
