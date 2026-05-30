import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/app_constants.dart';
import '../domain/lottery_result.dart';
import 'lottery_results_parser.dart';

class LotteryResultsRemoteSource {
  LotteryResultsRemoteSource({
    http.Client? client,
    LotteryResultsParser? parser,
  })  : _client = client ?? http.Client(),
        _parser = parser ?? LotteryResultsParser();

  final http.Client _client;
  final LotteryResultsParser _parser;

  Future<List<LotteryResult>> fetchLatestResults() async {
    final apiResultsUrl = AppConstants.apiResultsUrl.trim();
    if (apiResultsUrl.isNotEmpty) {
      return _fetchFromApi(apiResultsUrl);
    }

    return _fetchFromSourceWebsite();
  }

  Future<List<LotteryResult>> _fetchFromApi(String apiResultsUrl) async {
    final response = await _client.get(
      Uri.parse(apiResultsUrl),
      headers: const {'Accept': 'application/json'},
    ).timeout(AppConstants.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LotteryResultsException(
        'No se pudieron cargar los resultados desde la API. Codigo ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rawResults = payload['results'] as List<dynamic>? ?? const [];
    final results = rawResults
        .whereType<Map<String, dynamic>>()
        .map(LotteryResult.fromJson)
        .where((result) => result.hasNumbers)
        .toList(growable: false);

    if (results.isEmpty) {
      throw const LotteryResultsException('La API no devolvio resultados.');
    }

    return results;
  }

  Future<List<LotteryResult>> _fetchFromSourceWebsite() async {
    final uri = Uri.parse(AppConstants.sourceUrl);
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'User-Agent': 'LoteriasRDApp/1.0 (+https://loteriasdominicanas.com/)',
      },
    ).timeout(AppConstants.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LotteryResultsException(
        'No se pudieron cargar los resultados. Codigo ${response.statusCode}.',
      );
    }

    final results = _parser.parse(response.body);
    if (results.isEmpty) {
      throw const LotteryResultsException(
        'La fuente no devolvio resultados legibles.',
      );
    }

    return results;
  }
}

class LotteryResultsException implements Exception {
  const LotteryResultsException(this.message);

  final String message;

  @override
  String toString() => message;
}
