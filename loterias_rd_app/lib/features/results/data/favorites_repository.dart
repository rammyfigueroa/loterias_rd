import 'package:shared_preferences/shared_preferences.dart';

class FavoritesRepository {
  static const _storageKey = 'favorite_lottery_results';

  Future<Set<String>> loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_storageKey)?.toSet() ?? <String>{};
  }

  Future<Set<String>> toggleFavorite(String key) async {
    final favorites = await loadFavorites();
    if (favorites.contains(key)) {
      favorites.remove(key);
    } else {
      favorites.add(key);
    }
    await _saveFavorites(favorites);
    return favorites;
  }

  Future<void> _saveFavorites(Set<String> favorites) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = favorites.toList()..sort();
    await preferences.setStringList(_storageKey, sorted);
  }
}
