import '../domain/dreams_catalog.dart';
import 'catalog_text.dart';

enum CatalogMatchType { number, canonicalExact, variantExact, phrase, partial }

class CatalogSearchResult {
  final CatalogEntry entry;
  final String matchedTerm;
  final CatalogMatchType matchType;
  final RelationType? relationType;
  final List<DocumentaryClaim> claims;
  final List<ConflictGroup> conflicts;
  final bool ambiguous;

  const CatalogSearchResult({
    required this.entry,
    required this.matchedTerm,
    required this.matchType,
    required this.relationType,
    required this.claims,
    required this.conflicts,
    required this.ambiguous,
  });
}

class DreamsCatalogSearch {
  final DreamsCatalog catalog;

  const DreamsCatalogSearch(this.catalog);

  List<CatalogSearchResult> search(String query) {
    final normalized = normalizeCatalogText(query);
    if (normalized.isEmpty) return const [];
    final matches = <_SearchCandidate>[];

    if (RegExp(r'^\d{2}$').hasMatch(normalized)) {
      for (final claim in catalog.claims) {
        if (claim.number == normalized) {
          matches.add(_SearchCandidate(
            catalog.entryById(claim.catalogEntryId),
            normalized,
            CatalogMatchType.number,
            null,
            0,
          ));
        }
      }
    } else {
      for (final entry in catalog.entries) {
        final canonical = normalizeCatalogText(entry.canonicalTerm);
        if (canonical == normalized) {
          matches.add(_SearchCandidate(
            entry,
            entry.canonicalTerm,
            CatalogMatchType.canonicalExact,
            RelationType.exact,
            0,
          ));
        } else if (_containsPhrase(canonical, normalized) ||
            _containsPhrase(normalized, canonical)) {
          matches.add(_SearchCandidate(
            entry,
            entry.canonicalTerm,
            CatalogMatchType.partial,
            RelationType.exact,
            4,
          ));
        }
        for (final variant in entry.variants) {
          final term = normalizeCatalogText(variant.term);
          if (term == normalized) {
            matches.add(_SearchCandidate(
              entry,
              variant.term,
              variant.relationType == RelationType.phrase
                  ? CatalogMatchType.phrase
                  : CatalogMatchType.variantExact,
              variant.relationType,
              variant.relationType == RelationType.exact ||
                      variant.relationType == RelationType.synonym
                  ? 1
                  : 2,
            ));
          } else if (_containsPhrase(term, normalized) ||
              _containsPhrase(normalized, term)) {
            matches.add(_SearchCandidate(
              entry,
              variant.term,
              CatalogMatchType.partial,
              variant.relationType,
              5,
            ));
          }
        }
      }
    }

    final bestByEntry = <String, _SearchCandidate>{};
    for (final candidate in matches) {
      final current = bestByEntry[candidate.entry.id];
      if (current == null || candidate.rank < current.rank) {
        bestByEntry[candidate.entry.id] = candidate;
      }
    }
    final ordered = bestByEntry.values.toList()
      ..sort((left, right) => left.rank.compareTo(right.rank) != 0
          ? left.rank.compareTo(right.rank)
          : left.entry.canonicalTerm.compareTo(right.entry.canonicalTerm));
    final exactTermEntryIds = matches
        .where((item) =>
            normalizeCatalogText(item.matchedTerm) == normalized &&
            item.matchType != CatalogMatchType.partial)
        .map((item) => item.entry.id)
        .toSet();
    final ambiguousIds = ordered
        .where((item) =>
            exactTermEntryIds.length > 1 &&
            item.relationType != RelationType.related)
        .map((item) => item.entry.id)
        .toSet();

    return ordered.map((candidate) {
      final claims = catalog.claimsFor(candidate.entry.id);
      return CatalogSearchResult(
        entry: candidate.entry,
        matchedTerm: candidate.matchedTerm,
        matchType: candidate.matchType,
        relationType: candidate.relationType,
        claims: claims,
        conflicts: catalog.conflictsForClaims(claims.map((item) => item.id)),
        ambiguous: ambiguousIds.contains(candidate.entry.id),
      );
    }).toList();
  }

  bool _containsPhrase(String text, String phrase) =>
      RegExp('(?:^| )${RegExp.escape(phrase)}(?:\$| )').hasMatch(text);
}

class _SearchCandidate {
  final CatalogEntry entry;
  final String matchedTerm;
  final CatalogMatchType matchType;
  final RelationType? relationType;
  final int rank;

  const _SearchCandidate(
    this.entry,
    this.matchedTerm,
    this.matchType,
    this.relationType,
    this.rank,
  );
}
