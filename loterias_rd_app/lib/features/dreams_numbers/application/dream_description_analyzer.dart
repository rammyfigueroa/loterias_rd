import '../domain/dreams_catalog.dart';
import 'catalog_text.dart';

class DreamAnalysisMatch {
  final CatalogEntry entry;
  final String matchedTerm;
  final String fragment;
  final int start;
  final int end;
  final RelationType relationType;
  final bool negated;
  final bool ambiguous;
  final bool associationEligible;
  final List<DocumentaryClaim> claims;
  final List<Source> sources;
  final List<ConflictGroup> conflicts;

  const DreamAnalysisMatch({
    required this.entry,
    required this.matchedTerm,
    required this.fragment,
    required this.start,
    required this.end,
    required this.relationType,
    required this.negated,
    required this.ambiguous,
    required this.associationEligible,
    required this.claims,
    required this.sources,
    required this.conflicts,
  });
}

class DreamAnalysisResult {
  final String input;
  final List<DreamAnalysisMatch> matches;

  const DreamAnalysisResult({required this.input, required this.matches});

  bool get hasDocumentaryMatches => matches.isNotEmpty;
  bool get hasActiveAssociations =>
      matches.any((item) => item.claims.isNotEmpty);
}

class DreamDescriptionAnalyzer {
  final DreamsCatalog catalog;

  const DreamDescriptionAnalyzer(this.catalog);

  DreamAnalysisResult analyze(String description) {
    if (description.trim().isEmpty) {
      return DreamAnalysisResult(input: description, matches: const []);
    }
    final scanText = _normalizeForScan(description);
    final candidates = <_AnalysisCandidate>[];
    for (final entry in catalog.entries) {
      candidates.addAll(_findTerm(
        scanText,
        entry,
        entry.canonicalTerm,
        RelationType.exact,
      ));
      for (final variant in entry.variants) {
        candidates.addAll(_findTerm(
          scanText,
          entry,
          variant.term,
          variant.relationType,
        ));
      }
    }

    candidates.sort((left, right) {
      final start = left.start.compareTo(right.start);
      if (start != 0) return start;
      final length = (right.end - right.start).compareTo(left.end - left.start);
      if (length != 0) return length;
      return _relationRank(left.relationType)
          .compareTo(_relationRank(right.relationType));
    });

    final selected = <_AnalysisCandidate>[];
    for (final candidate in candidates) {
      final duplicateEntry = selected.any((item) =>
          item.entry.id == candidate.entry.id &&
          item.start <= candidate.start &&
          item.end >= candidate.end);
      if (!duplicateEntry) selected.add(candidate);
    }

    final occurrenceCounts = <String, Set<String>>{};
    for (final item in selected) {
      occurrenceCounts
          .putIfAbsent('${item.start}:${item.end}', () => <String>{})
          .add(item.entry.id);
    }

    final matches = selected.map((candidate) {
      final precedingStart = candidate.start > 45 ? candidate.start - 45 : 0;
      final preceding = scanText.substring(precedingStart, candidate.start);
      final negated = RegExp(
        r'(?:^|\s)(?:no|nunca|sin|ningun|ninguna|ninguno)\s+(?:\w+\s+){0,4}$',
      ).hasMatch(preceding);
      final associationEligible = !negated &&
          (candidate.relationType == RelationType.exact ||
              candidate.relationType == RelationType.synonym ||
              candidate.relationType == RelationType.phrase);
      final claims = associationEligible
          ? catalog.claimsFor(candidate.entry.id)
          : <DocumentaryClaim>[];
      final sourceIds = claims.map((item) => item.sourceId).toSet();
      return DreamAnalysisMatch(
        entry: candidate.entry,
        matchedTerm: candidate.term,
        fragment: description.substring(candidate.start, candidate.end),
        start: candidate.start,
        end: candidate.end,
        relationType: candidate.relationType,
        negated: negated,
        ambiguous:
            occurrenceCounts['${candidate.start}:${candidate.end}']!.length > 1,
        associationEligible: associationEligible,
        claims: claims,
        sources: catalog.sources
            .where((source) => sourceIds.contains(source.id))
            .toList(),
        conflicts: catalog.conflictsForClaims(claims.map((item) => item.id)),
      );
    }).toList()
      ..sort((left, right) => left.start.compareTo(right.start));

    return DreamAnalysisResult(input: description, matches: matches);
  }

  List<_AnalysisCandidate> _findTerm(
    String scanText,
    CatalogEntry entry,
    String term,
    RelationType relationType,
  ) {
    final normalized = normalizeCatalogText(term);
    if (normalized.isEmpty) return const [];
    final words = normalized.split(' ').map(RegExp.escape).join(r'\s+');
    final expression = RegExp('(?<![a-z0-9])$words(?![a-z0-9])');
    return expression
        .allMatches(scanText)
        .map((match) => _AnalysisCandidate(
              entry,
              term,
              relationType,
              match.start,
              match.end,
            ))
        .toList();
  }

  int _relationRank(RelationType type) {
    switch (type) {
      case RelationType.exact:
        return 0;
      case RelationType.phrase:
        return 1;
      case RelationType.synonym:
        return 2;
      case RelationType.related:
      case RelationType.narrower:
      case RelationType.broader:
        return 3;
    }
  }

  String _normalizeForScan(String value) {
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
      'Á': 'a',
      'É': 'e',
      'Í': 'i',
      'Ó': 'o',
      'Ú': 'u',
      'Ü': 'u',
      'Ñ': 'n',
    };
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final normalized = replacements[character] ?? character.toLowerCase();
      buffer.write(RegExp(r'[a-z0-9]').hasMatch(normalized) ? normalized : ' ');
    }
    return buffer.toString();
  }
}

class _AnalysisCandidate {
  final CatalogEntry entry;
  final String term;
  final RelationType relationType;
  final int start;
  final int end;

  const _AnalysisCandidate(
    this.entry,
    this.term,
    this.relationType,
    this.start,
    this.end,
  );
}
