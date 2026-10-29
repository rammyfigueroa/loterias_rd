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

  Uri _uri(
    StatisticsDrawOption draw,
    String path, [
    Map<String, String> extra = const {},
  ]) {
    if (baseUrl.trim().isEmpty) {
      throw const StatisticsApiException(
          'La API estadística de desarrollo no está configurada.');
    }
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path').replace(
      queryParameters: {
        'operatorId': draw.operatorId,
        'drawId': draw.drawId,
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

  Future<IntervalRankingResponse> getIntervals(
    StatisticsDrawOption draw,
    String coverage,
  ) async {
    final json = await _getAllPages(
      draw,
      '/statistics/first-prize/intervals',
      {'coverage': coverage},
      resultKey: 'results',
    );
    return IntervalRankingResponse.fromJson(json);
  }

  Future<IntervalDetail> getIntervalDetail(
    StatisticsDrawOption draw,
    int days,
    String coverage,
  ) async {
    final json = await _getAllPages(
      draw,
      '/statistics/first-prize/intervals/$days',
      {'coverage': coverage},
      resultKey: 'occurrences',
    );
    return IntervalDetail.fromJson(json);
  }

  Future<NumberStatisticsResponse> getNumbers(
    StatisticsDrawOption draw,
  ) async {
    final json = await _getAllPages(
      draw,
      '/statistics/first-prize/numbers',
      const {},
      resultKey: 'results',
    );
    return NumberStatisticsResponse.fromJson(json);
  }

  Future<Map<String, dynamic>> _getAllPages(
    StatisticsDrawOption draw,
    String path,
    Map<String, String> parameters, {
    required String resultKey,
  }) async {
    Map<String, dynamic>? firstPage;
    final combined = <dynamic>[];
    String? cursor;
    do {
      final page = await _get(_uri(draw, path, {
        ...parameters,
        'limit': '100',
        if (cursor != null) 'cursor': cursor,
      }));
      firstPage ??= page;
      final container = resultKey == 'occurrences'
          ? Map<String, dynamic>.from(page[resultKey] as Map)
          : page;
      combined.addAll(container['results'] as List? ?? const []);
      cursor = container['hasMore'] == true
          ? _textCursor(container['nextCursor'])
          : null;
    } while (cursor != null);

    final result = Map<String, dynamic>.from(firstPage);
    if (resultKey == 'occurrences') {
      final occurrences = Map<String, dynamic>.from(result[resultKey] as Map);
      occurrences['results'] = combined;
      occurrences['count'] = combined.length;
      occurrences['hasMore'] = false;
      occurrences['nextCursor'] = null;
      result[resultKey] = occurrences;
    } else {
      result['results'] = combined;
      result['count'] = combined.length;
      result['hasMore'] = false;
      result['nextCursor'] = null;
    }
    return result;
  }

  String? _textCursor(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
