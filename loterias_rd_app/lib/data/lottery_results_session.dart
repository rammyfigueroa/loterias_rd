import 'package:flutter/foundation.dart';

import 'lottery_results_remote_source.dart';
import 'lottery_results_repository.dart';

enum LotteryResultsSessionState { idle, loading, ready, refreshing, error }

class LotteryResultsSession extends ChangeNotifier {
  static const Duration defaultTimeToLive = Duration(minutes: 5);

  final LotteryResultsLoader loader;
  final Duration timeToLive;
  final DateTime Function() _now;

  LotteryResultsResponse? _response;
  DateTime? _fetchedAt;
  Object? _error;
  Future<LotteryResultsResponse>? _inFlight;
  int _generation = 0;
  LotteryResultsSessionState _state = LotteryResultsSessionState.idle;

  LotteryResultsSession({
    required this.loader,
    this.timeToLive = defaultTimeToLive,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  LotteryResultsSessionState get state => _state;
  LotteryResultsResponse? get response => _response;
  Object? get error => _error;
  bool get hasData => _response != null;
  bool get isRefreshing => _state == LotteryResultsSessionState.refreshing;

  bool get isCacheFresh {
    if (_response == null || _fetchedAt == null) return false;
    return _now().difference(_fetchedAt!) < timeToLive;
  }

  Future<LotteryResultsResponse> load({bool forceRefresh = false}) {
    if (!forceRefresh && isCacheFresh) {
      return Future<LotteryResultsResponse>.value(_response!);
    }
    final active = _inFlight;
    if (active != null) return active;

    final requestGeneration = ++_generation;
    _error = null;
    _state = hasData
        ? LotteryResultsSessionState.refreshing
        : LotteryResultsSessionState.loading;
    notifyListeners();

    final request = loader.getLatestResults();
    late final Future<LotteryResultsResponse> guarded;
    guarded = request.then((value) {
      if (requestGeneration == _generation) {
        _response = value;
        _fetchedAt = _now();
        _error = null;
        _state = LotteryResultsSessionState.ready;
        notifyListeners();
      }
      return value;
    }, onError: (Object error, StackTrace stackTrace) {
      if (requestGeneration == _generation) {
        _error = error;
        _state = LotteryResultsSessionState.error;
        notifyListeners();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }).whenComplete(() {
      if (identical(_inFlight, guarded)) _inFlight = null;
    });
    _inFlight = guarded;
    return guarded;
  }

  Future<LotteryResultsResponse> refresh() => load(forceRefresh: true);

  void invalidate({bool clearData = false}) {
    _generation++;
    _inFlight = null;
    _fetchedAt = null;
    _error = null;
    if (clearData) _response = null;
    _state = hasData
        ? LotteryResultsSessionState.ready
        : LotteryResultsSessionState.idle;
    notifyListeners();
  }
}
