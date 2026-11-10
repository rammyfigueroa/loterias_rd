import 'package:flutter/foundation.dart';

import 'favorites_repository.dart';

class FavoritesSession extends ChangeNotifier {
  final LotteryFavoritesStore store;

  Set<String> _favoriteLotteryIds = <String>{};
  final Set<String> _pendingLotteryIds = <String>{};
  Future<Set<String>>? _loadInFlight;
  Future<void> _writeQueue = Future<void>.value();
  Object? _error;
  bool _isLoaded = false;

  FavoritesSession({required this.store});

  Set<String> get favoriteLotteryIds =>
      Set<String>.unmodifiable(_favoriteLotteryIds);
  Object? get error => _error;
  bool get isLoaded => _isLoaded;
  bool isFavorite(String id) => _favoriteLotteryIds.contains(id);
  bool isPending(String id) => _pendingLotteryIds.contains(id);

  Future<Set<String>> load({bool forceRefresh = false}) {
    if (_isLoaded && !forceRefresh) {
      return Future<Set<String>>.value(favoriteLotteryIds);
    }
    final active = _loadInFlight;
    if (active != null) return active;

    _error = null;
    late final Future<Set<String>> guarded;
    guarded = store.getFavoriteLotteryIds().then((value) {
      _favoriteLotteryIds = Set<String>.from(value);
      _isLoaded = true;
      _error = null;
      notifyListeners();
      return favoriteLotteryIds;
    }, onError: (Object error, StackTrace stackTrace) {
      _error = error;
      notifyListeners();
      Error.throwWithStackTrace(error, stackTrace);
    }).whenComplete(() {
      if (identical(_loadInFlight, guarded)) _loadInFlight = null;
    });
    _loadInFlight = guarded;
    return guarded;
  }

  Future<bool> toggleLottery(String id) async {
    if (_pendingLotteryIds.contains(id)) return isFavorite(id);

    final wasFavorite = isFavorite(id);
    final nextFavorite = !wasFavorite;
    _setFavorite(id, nextFavorite);
    _pendingLotteryIds.add(id);
    _error = null;
    notifyListeners();

    final operation = _writeQueue.then((_) async {
      final persisted = await store.toggleFavoriteLottery(id);
      _setFavorite(id, persisted);
      _isLoaded = true;
      _error = null;
      return persisted;
    });
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});

    try {
      return await operation;
    } catch (error, stackTrace) {
      _setFavorite(id, wasFavorite);
      _error = error;
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _pendingLotteryIds.remove(id);
      notifyListeners();
    }
  }

  void _setFavorite(String id, bool value) {
    if (value) {
      _favoriteLotteryIds.add(id);
    } else {
      _favoriteLotteryIds.remove(id);
    }
  }
}
