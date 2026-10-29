import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/first_prize_statistics.dart';

class StatisticsApiException implements Exception {
  final String message;
  const StatisticsApiException(this.message);

  @override
  String toString() => message;
}

class FirstPrizeStatisticsRemoteSource {
  final String baseUrl;
  final http.Client client;

  FirstPrizeStatisticsRemoteSource({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String> extra = const {}]) {
    if (baseUrl.trim().isEmpty) {
      throw const StatisticsApiException(
          'La API estadística de desarrollo no está configurada.');
    }
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path').replace(
      queryParameters: {
        'operatorId': StatisticsSeries.operatorId,
        'drawId': StatisticsSeries.drawId,
        ...extra,
      },
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw StatisticsApiException(
          'La API estadística respondió ${response.statusCode}.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map)
      throw const StatisticsApiException(
          'La respuesta estadística no es válida.');
    return Map<String, dynamic>.from(decoded);
  }

  Future<IntervalRankingResponse> getIntervals(String coverage) async {
    final json = await _get(_uri('/statistics/first-prize/intervals', {
      'coverage': coverage,
      'limit': '100',
    }));
    return IntervalRankingResponse.fromJson(json);
  }

  Future<IntervalDetail> getIntervalDetail(int days, String coverage) async {
    final json = await _get(_uri('/statistics/first-prize/intervals/$days', {
      'coverage': coverage,
      'limit': '100',
    }));
    return IntervalDetail.fromJson(json);
  }

  Future<NumberStatisticsResponse> getNumbers() async {
    final json =
        await _get(_uri('/statistics/first-prize/numbers', {'limit': '100'}));
    return NumberStatisticsResponse.fromJson(json);
  }
}
