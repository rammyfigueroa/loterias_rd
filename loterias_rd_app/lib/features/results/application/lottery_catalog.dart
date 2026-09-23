import '../../../domain/lottery_result.dart';

class LotteryGroup {
  final String id;
  final String name;
  final List<LotteryResult> results;

  const LotteryGroup({
    required this.id,
    required this.name,
    required this.results,
  });

  LotteryResult get latestResult => results.first;
}

String normalizeLotteryText(String value) {
  return value
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
}

String lotteryId(String lotteryName) => normalizeLotteryText(lotteryName);

List<String> resultNumbers(LotteryResult result) {
  if (result.prizes.isNotEmpty) {
    return result.prizes.map((prize) => prize.number).toList();
  }
  return result.numbers;
}

DateTime? parseDrawDate(String value, {DateTime? now}) {
  final text = value.trim();
  if (text.isEmpty) return null;

  DateTime? validDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    if (date.year == year && date.month == month && date.day == day) {
      return date;
    }
    return null;
  }

  final iso = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(text);
  if (iso != null) {
    return validDate(
      int.parse(iso.group(1)!),
      int.parse(iso.group(2)!),
      int.parse(iso.group(3)!),
    );
  }

  final local =
      RegExp(r'^(\d{1,2})[-/.](\d{1,2})(?:[-/.](\d{4}))?').firstMatch(text);
  if (local != null) {
    return validDate(
      int.tryParse(local.group(3) ?? '') ?? (now ?? DateTime.now()).year,
      int.parse(local.group(2)!),
      int.parse(local.group(1)!),
    );
  }
  return null;
}

DateTime? resultDateTime(LotteryResult result, {DateTime? now}) {
  final date = parseDrawDate(result.drawDate, now: now);
  if (date == null) return null;

  final timeMatch = RegExp(
    r'\b(\d{1,2}):(\d{2})\s*(AM|PM)\b',
    caseSensitive: false,
  ).firstMatch(result.drawName);
  if (timeMatch == null) return date;

  var hour = int.parse(timeMatch.group(1)!);
  final minute = int.parse(timeMatch.group(2)!);
  final period = timeMatch.group(3)!.toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

int compareResultsNewestFirst(LotteryResult a, LotteryResult b) {
  final aDate = resultDateTime(a);
  final bDate = resultDateTime(b);
  if (aDate == null && bDate == null) return 0;
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return bDate.compareTo(aDate);
}

List<LotteryResult> sortResultsNewestFirst(Iterable<LotteryResult> results) {
  return List<LotteryResult>.from(results)..sort(compareResultsNewestFirst);
}

List<LotteryGroup> groupResultsByLottery(Iterable<LotteryResult> results) {
  final grouped = <String, List<LotteryResult>>{};
  final names = <String, String>{};

  for (final result in results) {
    final id = lotteryId(result.lotteryName);
    if (id.isEmpty) continue;
    names.putIfAbsent(id, () => result.lotteryName.trim());
    grouped.putIfAbsent(id, () => <LotteryResult>[]).add(result);
  }

  final groups = grouped.entries.map((entry) {
    return LotteryGroup(
      id: entry.key,
      name: names[entry.key]!,
      results: sortResultsNewestFirst(entry.value),
    );
  }).toList();

  groups.sort((a, b) {
    final recent = compareResultsNewestFirst(a.latestResult, b.latestResult);
    return recent != 0 ? recent : a.name.compareTo(b.name);
  });
  return groups;
}

bool resultMatchesQuery(LotteryResult result, String query) {
  final normalizedQuery = normalizeLotteryText(query);
  if (normalizedQuery.isEmpty) return true;
  final searchable = <String>[
    result.lotteryName,
    result.drawName,
    result.drawDate,
    ...resultNumbers(result),
  ].map(normalizeLotteryText);
  return searchable.any((value) => value.contains(normalizedQuery));
}

List<LotteryResult> searchResults(
  Iterable<LotteryResult> results,
  String query,
) {
  return results.where((result) => resultMatchesQuery(result, query)).toList();
}
