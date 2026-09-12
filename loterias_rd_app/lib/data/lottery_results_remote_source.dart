import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/lottery_result.dart';

/// Response object encapsulating the updated timestamp and results list.
class LotteryResultsResponse {
  final String updatedAt;
  final List<LotteryResult> results;

  LotteryResultsResponse({
    required this.updatedAt,
    required this.results,
  });
}

/// Data source that fetches lottery results from a remote API.
///
/// The API URL is provided via the `LOTTERIES_API_URL` compile-time environment
/// variable. When running the app you can specify it with
/// `--dart-define=LOTTERIES_API_URL=...`.
class LotteryResultsRemoteSource {
  final String apiUrl;

  LotteryResultsRemoteSource()
      : apiUrl = const String.fromEnvironment('LOTTERIES_API_URL',
            defaultValue: 'https://api.sorteosdominicanos.workers.dev/results');

  /// Fetch the latest results from the remote API.
  Future<LotteryResultsResponse> getLatestResults() async {
    if (apiUrl.isEmpty) {
      throw Exception('API URL not provided');
    }
    final uri = Uri.parse(apiUrl);
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch results: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final resultsList = (data['results'] as List)
        .map((item) => LotteryResult.fromJson(item))
        .toList();
    return LotteryResultsResponse(
      updatedAt: data['updatedAt'] ?? '',
      results: resultsList,
    );
  }
}