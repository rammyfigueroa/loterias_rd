import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../domain/lottery_result.dart';

class LotteryResultsParser {
  static const _lotteryGroups = <String>{
    'Nacional',
    'Leidsa',
    'Loteria Real',
    'Loteka',
    'Americanas',
    'La Primera',
    'La Suerte',
    'LoteDom',
    'Anguila',
    'King Lottery',
  };

  List<LotteryResult> parse(String html) {
    final document = html_parser.parse(html);
    final bodyText = document.body?.text ?? document.text ?? '';

    final semanticResults = _parseFromResultCards(document);
    if (semanticResults.isNotEmpty) return semanticResults;

    return _parseFromVisibleText(bodyText);
  }

  List<LotteryResult> _parseFromResultCards(Document document) {
    final candidates = document
        .querySelectorAll('article, .game-block, .resultados, .resultado, .card')
        .where((node) => _extractNumbers(node.text).isNotEmpty)
        .toList();

    if (candidates.length < 3) return const [];

    return candidates.map(_cardToResult).whereType<LotteryResult>().toList();
  }

  LotteryResult? _cardToResult(Element element) {
    final textLines = _normalizeLines(element.text);
    if (textLines.isEmpty) return null;

    final date = textLines.firstWhere(_looksLikeDate, orElse: () => 'Hoy');
    final numbers = _extractNumbers(element.text);
    if (numbers.isEmpty) return null;

    final drawName = textLines.firstWhere(
      (line) => !_looksLikeDate(line) && _extractNumbers(line).isEmpty,
      orElse: () => 'Sorteo',
    );

    return LotteryResult(
      lotteryName: _guessLotteryName(drawName),
      drawName: drawName,
      drawDate: date,
      numbers: numbers,
      isVerified: element.text.contains('✓'),
    );
  }

  List<LotteryResult> _parseFromVisibleText(String text) {
    final lines = _normalizeLines(text)
        .where((line) => !_ignoredLine(line))
        .toList(growable: false);

    final results = <LotteryResult>[];
    var currentLottery = 'Loterias Dominicanas';

    for (var i = 0; i < lines.length - 2; i++) {
      final line = lines[i];
      if (_lotteryGroups.contains(line)) {
        currentLottery = line;
        continue;
      }

      if (!_looksLikeDate(line)) continue;

      final drawName = _nextMeaningfulLine(lines, i + 1);
      if (drawName == null || _lotteryGroups.contains(drawName)) continue;

      final numberLineIndex = _nextNumberLineIndex(lines, i + 2);
      if (numberLineIndex == null) continue;

      final numbers = _extractNumbers(lines[numberLineIndex]);
      if (numbers.isEmpty) continue;

      results.add(
        LotteryResult(
          lotteryName: currentLottery,
          drawName: drawName,
          drawDate: line,
          numbers: numbers,
          prize: _extractPrize(lines, numberLineIndex + 1),
          isVerified: true,
        ),
      );

      i = numberLineIndex;
    }

    return _deduplicate(results);
  }

  List<String> _normalizeLines(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .split(RegExp(r'\n+'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  bool _ignoredLine(String line) {
    const ignored = {
      '¿Ganaste?',
      'Gracias, Resultados Pronto',
      'Resultados Anteriores',
      'Open Menu',
      'Loterias Dominicanas',
      'GRATIS -',
    };
    return ignored.contains(line) || line.startsWith('Image:');
  }

  String? _nextMeaningfulLine(List<String> lines, int start) {
    for (var i = start; i < lines.length && i < start + 6; i++) {
      final line = lines[i];
      if (_ignoredLine(line) || _looksLikeDate(line)) continue;
      if (_extractNumbers(line).length > 1) continue;
      return line;
    }
    return null;
  }

  int? _nextNumberLineIndex(List<String> lines, int start) {
    for (var i = start; i < lines.length && i < start + 8; i++) {
      final numbers = _extractNumbers(lines[i]);
      if (numbers.length >= 2) return i;
    }
    return null;
  }

  List<String> _extractNumbers(String text) {
    return RegExp(r'\b\d{1,3}(?:X)?\b')
        .allMatches(text)
        .map((match) => match.group(0)!)
        .where((value) => value.length <= 3 || value.endsWith('X'))
        .toList();
  }

  bool _looksLikeDate(String value) {
    return RegExp(r'^\d{1,2}-\d{1,2}$').hasMatch(value) ||
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);
  }

  String _guessLotteryName(String drawName) {
    final lower = drawName.toLowerCase();
    if (lower.contains('leidsa') || lower.contains('loto pool')) return 'Leidsa';
    if (lower.contains('real')) return 'Loteria Real';
    if (lower.contains('loteka') || lower.contains('mega')) return 'Loteka';
    if (lower.contains('primera')) return 'La Primera';
    if (lower.contains('suerte')) return 'La Suerte';
    if (lower.contains('lotedom') || lower.contains('quemaito')) return 'LoteDom';
    if (lower.contains('anguila')) return 'Anguila';
    if (lower.contains('king')) return 'King Lottery';
    if (lower.contains('florida') || lower.contains('new york')) return 'Americanas';
    return 'Nacional';
  }

  String? _extractPrize(List<String> lines, int start) {
    if (start >= lines.length) return null;
    final candidate = lines[start];
    final looksLikeMoney = RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(candidate);
    return looksLikeMoney ? candidate : null;
  }

  List<LotteryResult> _deduplicate(List<LotteryResult> results) {
    final seen = <String>{};
    return results.where((result) {
      final key = '${result.lotteryName}|${result.drawName}|${result.drawDate}';
      return seen.add(key);
    }).toList(growable: false);
  }
}
