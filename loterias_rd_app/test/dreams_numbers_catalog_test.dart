import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/application/dream_description_analyzer.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/application/dreams_catalog_search.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/application/publishable_catalog.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/data/dreams_catalog_loader.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/domain/catalog_validation.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/domain/dreams_catalog.dart';

const fixturePath = 'test/fixtures/dreams_numbers_fixture.json';
final publicationContext = PublicationContext(
  referenceDate: DateTime.utc(2026, 11, 9),
);

Map<String, dynamic> publishableFixture(String fixtureText) {
  final json = jsonDecode(fixtureText) as Map<String, dynamic>;
  final metadata = json['metadata'] as Map<String, dynamic>;
  metadata['schemaVersion'] = '1.2.0';
  metadata['editorialStatus'] = 'approved';
  final evidence = <Map<String, dynamic>>[];
  for (final source in json['sources'] as List<dynamic>) {
    source['rightsStatus'] = 'authorized';
    source['verificationStatus'] = 'verified';
    final sourceId = source['id'] as String;
    evidence.add({
      'id': 'evidence_$sourceId',
      'sourceId': sourceId,
      'rightsHolder': 'Titular sintético de pruebas',
      'authorizationType': 'writtenPermission',
      'legalBasisType': 'explicitPermission',
      'evidenceReference': 'fixture://permission/$sourceId',
      'evidenceDate': '2026-01-01',
      'validFrom': '2026-01-01',
      'validUntil': '2027-12-31',
      'indefiniteTermJustification': null,
      'territory': 'worldwide',
      'territories': <String>[],
      'commercialUseAllowed': true,
      'redistributionAllowed': true,
      'derivativeWorksAllowed': true,
      'attributionRequired': false,
      'restrictions': <String>[],
      'reviewStatus': 'approved',
      'reviewedAt': '2026-01-02',
      'scopeType': 'fullSource',
      'scopeReferences': [sourceId],
    });
  }
  for (final claim in json['claims'] as List<dynamic>) {
    claim['verificationStatus'] = 'verified';
    claim['rightsEvidenceIds'] = ['evidence_${claim['sourceId']}'];
  }
  for (final interpretation in json['interpretations'] as List<dynamic>) {
    interpretation['verificationStatus'] = 'verified';
    interpretation['publicationStatus'] = 'approved';
    interpretation['rightsEvidenceIds'] =
        (interpretation['sourceReferences'] as List<dynamic>)
            .map((id) => 'evidence_$id')
            .toList();
  }
  json['rightsEvidence'] = evidence;
  json['articles'] = <dynamic>[];
  return json;
}

Map<String, dynamic> articleFixtureForBasis(
  String fixtureText,
  String basis,
) {
  final json = publishableFixture(fixtureText);
  final source = Map<String, dynamic>.from(
    (json['sources'] as List<dynamic>).first as Map,
  );
  final sourceId = source['id'] as String;
  final articleId = 'article_fixture_original';
  final evidence = Map<String, dynamic>.from(
    (json['rightsEvidence'] as List<dynamic>).first as Map,
  )
    ..['legalBasisType'] = basis
    ..['scopeType'] = 'article'
    ..['scopeReferences'] = [articleId];

  switch (basis) {
    case 'explicitPermission':
      evidence['authorizationType'] = 'writtenPermission';
    case 'originalWork':
      source['rightsStatus'] = 'permissionPending';
      evidence
        ..['authorizationType'] = 'other'
        ..['authorshipReference'] = 'fixture://authorship/article'
        ..['originalityDeclaration'] = 'Declaración sintética de originalidad.'
        ..['editorialReviewReference'] = 'fixture://editorial-review/article'
        ..['historicalFactReferences'] = [sourceId]
        ..['unauthorizedReproductionConfirmedAbsent'] = true;
    case 'compatibleOpenLicense':
      evidence
        ..['authorizationType'] = 'openLicense'
        ..['licenseIdentifier'] = 'Fixture License'
        ..['licenseVersion'] = '1.0'
        ..['licenseUrl'] = 'https://example.invalid/fixture-license'
        ..['licenseConditions'] = ['attribution', 'commercial-use']
        ..['attributionReference'] = 'Fixture attribution';
    case 'reviewedLegalException':
      evidence
        ..['authorizationType'] = 'other'
        ..['legalJurisdiction'] = 'TEST'
        ..['legalException'] = 'synthetic-review-only'
        ..['legalReviewReference'] = 'fixture://legal-review/article'
        ..['legalReviewerRole'] = 'Synthetic legal reviewer'
        ..['legalConclusionDate'] = '2026-01-03'
        ..['legalLimitations'] = ['article-only', 'fixture-only'];
  }

  json
    ..['sources'] = [source]
    ..['entries'] = <dynamic>[]
    ..['claims'] = <dynamic>[]
    ..['interpretations'] = <dynamic>[]
    ..['conflictGroups'] = <dynamic>[]
    ..['rightsEvidence'] = [evidence]
    ..['articles'] = [
      {
        'id': articleId,
        'title': 'Artículo sintético de prueba',
        'category': 'fixture',
        'text': 'Texto original sintético basado en un hecho de prueba.',
        'sourceReferences': [sourceId],
        'rightsEvidenceIds': [evidence['id']],
        'verificationStatus': 'verified',
        'rightsStatus': 'authorized',
        'publicationStatus': 'approved',
        'reviewedAt': '2026-01-04',
      }
    ];
  return json;
}

void main() {
  late String fixtureText;
  late DreamsCatalog catalog;

  setUpAll(() async {
    fixtureText = await File(fixturePath).readAsString();
    catalog = DreamsCatalogLoader().loadString(fixtureText);
  });

  group('catalog loader and schema', () {
    test('loads the synthetic fixture without production assets', () {
      expect(catalog.metadata.catalogVersion, 'fixture-1');
      expect(catalog.entries, hasLength(3));
      expect(catalog.claims.map((item) => item.number),
          containsAll(['10', '20', '30', '40']));
    });

    test('reports a missing file descriptively', () async {
      expect(
        () => DreamsCatalogLoader().loadFile('test/fixtures/missing.json'),
        throwsA(isA<CatalogLoadException>().having(
          (error) => error.message,
          'message',
          contains('could not be read'),
        )),
      );
    });

    test('rejects corrupt JSON', () {
      expect(
        () => DreamsCatalogLoader().loadString('{not-json'),
        throwsA(isA<CatalogLoadException>().having(
          (error) => error.message,
          'message',
          contains('corrupt'),
        )),
      );
    });

    test('rejects an incompatible schema version', () {
      final json = jsonDecode(fixtureText) as Map<String, dynamic>;
      (json['metadata'] as Map<String, dynamic>)['schemaVersion'] = '2.0.0';
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogValidationException>().having(
          (error) => error.toString(),
          'issues',
          contains('Unsupported schema version'),
        )),
      );
    });

    test('rejects duplicate identifiers', () {
      final json = jsonDecode(fixtureText) as Map<String, dynamic>;
      final entries = json['entries'] as List<dynamic>;
      entries.add(Map<String, dynamic>.from(entries.first as Map));
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogValidationException>().having(
          (error) => error.toString(),
          'issues',
          contains('Duplicate ID'),
        )),
      );
    });

    test('requires numbers to stay as two-digit strings from 00 to 99', () {
      final json = jsonDecode(fixtureText) as Map<String, dynamic>;
      (json['claims'] as List<dynamic>).first['number'] = '7';
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogValidationException>().having(
          (error) => error.toString(),
          'issues',
          contains('two-digit string'),
        )),
      );
    });

    test('rejects broken entry and source references', () {
      final json = jsonDecode(fixtureText) as Map<String, dynamic>;
      final claim = (json['claims'] as List<dynamic>).first;
      claim['catalogEntryId'] = 'missing_entry';
      claim['sourceId'] = 'missing_source';
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogValidationException>()
            .having(
                (error) => error.toString(), 'entry', contains('Unknown entry'))
            .having((error) => error.toString(), 'source',
                contains('Unknown source'))),
      );
    });

    test('preserves contradictory claims and their conflict group', () {
      final claims = catalog.claimsFor('simbolo_prueba_a');
      expect(claims.map((item) => item.number), ['10', '20']);
      expect(
        catalog.conflictsForClaims(claims.map((item) => item.id)).single.id,
        'conflict_fixture_a',
      );
    });

    test('blocks draft and permission-pending content from publication', () {
      final issues = const CatalogValidator()
          .validateForPublication(catalog, publicationContext);
      expect(
          issues.map((item) => item.message),
          contains(
            'Catalog is not approved for publication.',
          ));
      expect(
        issues.map((item) => item.message).join(' '),
        contains(
            'source_fixture_pending does not have explicit publication authorization'),
      );
      expect(
        () => const CatalogValidator()
            .requirePublishable(catalog, publicationContext),
        throwsA(isA<CatalogValidationException>()),
      );
    });

    test('explicitly rejects unauthorized source content for publication', () {
      final json = jsonDecode(fixtureText) as Map<String, dynamic>;
      final source = (json['sources'] as List<dynamic>).first;
      source['rightsStatus'] = 'unauthorized';
      final unauthorizedCatalog =
          DreamsCatalogLoader().loadString(jsonEncode(json));

      expect(
        const CatalogValidator()
            .validateForPublication(unauthorizedCatalog, publicationContext)
            .map((item) => item.message),
        contains(
          'Source source_fixture_authorized does not have explicit publication authorization.',
        ),
      );
      expect(
        () => const CatalogValidator()
            .requirePublishable(unauthorizedCatalog, publicationContext),
        throwsA(isA<CatalogValidationException>()),
      );
    });

    test('rejects an invalid optional source publication date', () {
      final json = jsonDecode(fixtureText) as Map<String, dynamic>;
      final source = (json['sources'] as List<dynamic>).first;
      source['publicationDate'] = 'not-a-date';

      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogValidationException>().having(
          (error) => error.toString(),
          'issues',
          contains('publicationDate'),
        )),
      );
    });

    test('rejects unknown JSON fields instead of silently ignoring them', () {
      final json = jsonDecode(fixtureText) as Map<String, dynamic>;
      (json['entries'] as List<dynamic>).first['unexpectedField'] = true;

      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogLoadException>().having(
          (error) => error.toString(),
          'message',
          contains('unsupported fields'),
        )),
      );
    });
  });

  group('strict publication policy', () {
    for (final basis in [
      'explicitPermission',
      'originalWork',
      'compatibleOpenLicense',
      'reviewedLegalException',
    ]) {
      test('accepts valid synthetic $basis evidence', () {
        final parsed = DreamsCatalogLoader()
            .loadString(jsonEncode(articleFixtureForBasis(fixtureText, basis)));
        final result = const PublishableCatalogGate()
            .evaluate(parsed, context: publicationContext);
        expect(result.isAvailable, isTrue);
        expect(
            result.catalog!.rightsEvidence.single.legalBasisType!.name, basis);
      });
    }

    test('rejects legacy schema 1.1 from the publication gate', () {
      final json = publishableFixture(fixtureText);
      (json['metadata'] as Map<String, dynamic>)['schemaVersion'] = '1.1.0';
      for (final evidence in json['rightsEvidence'] as List<dynamic>) {
        evidence.remove('legalBasisType');
      }
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      expect(
        const PublishableCatalogGate()
            .evaluate(parsed, context: publicationContext)
            .isAvailable,
        isFalse,
      );
    });

    test('rejects original work without authorship evidence', () {
      final json = articleFixtureForBasis(fixtureText, 'originalWork');
      (json['rightsEvidence'] as List<dynamic>).first['authorshipReference'] =
          null;
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      expect(
        const PublishableCatalogGate()
            .evaluate(parsed, context: publicationContext)
            .isAvailable,
        isFalse,
      );
    });

    test('rejects explicit permission without its document', () {
      final json = articleFixtureForBasis(fixtureText, 'explicitPermission');
      (json['rightsEvidence'] as List<dynamic>)
          .first
          .remove('evidenceReference');
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogLoadException>()),
      );
    });

    test('rejects an open license without verified conditions', () {
      final json = articleFixtureForBasis(fixtureText, 'compatibleOpenLicense');
      (json['rightsEvidence'] as List<dynamic>).first['licenseVersion'] = null;
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      expect(
        const PublishableCatalogGate()
            .evaluate(parsed, context: publicationContext)
            .isAvailable,
        isFalse,
      );
    });

    test('rejects a legal exception without documented review', () {
      final json =
          articleFixtureForBasis(fixtureText, 'reviewedLegalException');
      (json['rightsEvidence'] as List<dynamic>).first['legalReviewReference'] =
          null;
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      expect(
        const PublishableCatalogGate()
            .evaluate(parsed, context: publicationContext)
            .isAvailable,
        isFalse,
      );
    });

    test('rejects unknown rights even for a factual original-work source', () {
      final json = articleFixtureForBasis(fixtureText, 'originalWork');
      (json['sources'] as List<dynamic>).first['rightsStatus'] = 'unknown';
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      expect(
        const PublishableCatalogGate()
            .evaluate(parsed, context: publicationContext)
            .isAvailable,
        isFalse,
      );
    });

    test('accepts a fully verified and explicitly authorized catalog', () {
      final approved = DreamsCatalogLoader()
          .loadString(jsonEncode(publishableFixture(fixtureText)));
      final result = const PublishableCatalogGate()
          .evaluate(approved, context: publicationContext);

      expect(result.isAvailable, isTrue);
      expect(result.issues, isEmpty);
      expect(
          result.catalog!
              .claimsFor('simbolo_prueba_a')
              .map((item) => item.number),
          ['10', '20']);
      expect(result.catalog!.conflictGroups.single.claimIds,
          ['claim_fixture_a_10', 'claim_fixture_a_20']);
    });

    test('rejects authorized sources without rights evidence', () {
      final json = publishableFixture(fixtureText)..['rightsEvidence'] = [];
      for (final claim in json['claims'] as List<dynamic>) {
        claim['rightsEvidenceIds'] = <String>[];
      }
      for (final interpretation in json['interpretations'] as List<dynamic>) {
        interpretation['rightsEvidenceIds'] = <String>[];
      }
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      final result = const PublishableCatalogGate()
          .evaluate(parsed, context: publicationContext);
      expect(result.isAvailable, isFalse);
      expect(result.issues.map((item) => item.message).join(' '),
          contains('has no rights evidence'));
    });

    test('rejects missing evidence and source references', () {
      final unknownEvidence = publishableFixture(fixtureText);
      (unknownEvidence['claims'] as List<dynamic>).first['rightsEvidenceIds'] =
          ['missing_evidence'];
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(unknownEvidence)),
        throwsA(isA<CatalogValidationException>()),
      );

      final unknownSource = publishableFixture(fixtureText);
      (unknownSource['rightsEvidence'] as List<dynamic>).first['sourceId'] =
          'missing_source';
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(unknownSource)),
        throwsA(isA<CatalogValidationException>()),
      );
    });

    test('rejects empty rights holder and evidence reference', () {
      final json = publishableFixture(fixtureText);
      final evidence = (json['rightsEvidence'] as List<dynamic>).first;
      evidence['rightsHolder'] = '';
      evidence['evidenceReference'] = '';
      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogLoadException>()),
      );
    });

    for (final testCase in <String, void Function(Map<String, dynamic>)>{
      'insufficient scope': (evidence) {
        evidence['scopeType'] = 'article';
        evidence['scopeReferences'] = ['unrelated_article'];
      },
      'commercial use prohibited': (evidence) {
        evidence['commercialUseAllowed'] = false;
      },
      'redistribution prohibited': (evidence) {
        evidence['redistributionAllowed'] = false;
      },
      'derivative works prohibited': (evidence) {
        evidence['derivativeWorksAllowed'] = false;
      },
      'expired permission': (evidence) {
        evidence['validUntil'] = '2026-11-08';
      },
      'future permission': (evidence) {
        evidence['validFrom'] = '2026-11-10';
      },
      'incompatible territory': (evidence) {
        evidence['territory'] = 'dominicanRepublic';
      },
      'pending rights review': (evidence) {
        evidence['reviewStatus'] = 'pending';
      },
      'unverified open license': (evidence) {
        evidence['authorizationType'] = 'openLicense';
        evidence['commercialUseAllowed'] = false;
      },
      'article authorization used for a table': (evidence) {
        evidence['scopeType'] = 'article';
        evidence['scopeReferences'] = ['claim_fixture_a_10'];
      },
    }.entries) {
      test('rejects ${testCase.key}', () {
        final json = publishableFixture(fixtureText);
        testCase.value((json['rightsEvidence'] as List<dynamic>).first
            as Map<String, dynamic>);
        final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
        expect(
          const PublishableCatalogGate()
              .evaluate(parsed, context: publicationContext)
              .isAvailable,
          isFalse,
        );
      });
    }

    test('rejects restrictions incompatible with the publication context', () {
      final json = publishableFixture(fixtureText);
      (json['rightsEvidence'] as List<dynamic>).first['restrictions'] = [
        'no_mobile_apps'
      ];
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      final context = PublicationContext(
        referenceDate: DateTime.utc(2026, 11, 9),
        incompatibleRestrictions: const {'no_mobile_apps'},
      );
      expect(
        const PublishableCatalogGate()
            .evaluate(parsed, context: context)
            .isAvailable,
        isFalse,
      );
    });

    test('keeps cultural articles in review outside the publishable wrapper',
        () {
      final json = publishableFixture(fixtureText);
      json['articles'] = [
        {
          'id': 'article_fixture_review',
          'title': 'Artículo cultural sintético',
          'category': 'fixture',
          'text': 'Texto original sintético sin asociaciones numéricas.',
          'sourceReferences': ['source_fixture_authorized'],
          'rightsEvidenceIds': ['evidence_source_fixture_authorized'],
          'verificationStatus': 'supported',
          'rightsStatus': 'permissionPending',
          'publicationStatus': 'review',
          'reviewedAt': '2026-11-09',
        }
      ];
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));
      final result = const PublishableCatalogGate()
          .evaluate(parsed, context: publicationContext);
      expect(
          parsed.articles.single.publicationStatus, PublicationStatus.review);
      expect(result.isAvailable, isFalse);
    });

    for (final status in ['supported', 'disputed', 'unverified', 'rejected']) {
      test('rejects an approved interpretation with $status verification', () {
        final json = publishableFixture(fixtureText);
        (json['interpretations'] as List<dynamic>).first['verificationStatus'] =
            status;
        final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));

        expect(
          const PublishableCatalogGate()
              .evaluate(parsed, context: publicationContext)
              .isAvailable,
          isFalse,
        );
      });
    }

    test('rejects an approved interpretation without source references', () {
      final json = publishableFixture(fixtureText);
      (json['interpretations'] as List<dynamic>).first['sourceReferences'] =
          <String>[];
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));

      expect(
          const PublishableCatalogGate()
              .evaluate(parsed, context: publicationContext)
              .isAvailable,
          isFalse);
    });

    test('rejects an interpretation with an unknown source reference', () {
      final json = publishableFixture(fixtureText);
      (json['interpretations'] as List<dynamic>).first['sourceReferences'] = [
        'missing_source'
      ];

      expect(
        () => DreamsCatalogLoader().loadString(jsonEncode(json)),
        throwsA(isA<CatalogValidationException>()),
      );
    });

    test('rejects a source that is not verified', () {
      final json = publishableFixture(fixtureText);
      (json['sources'] as List<dynamic>).first['verificationStatus'] =
          'supported';
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));

      expect(
          const PublishableCatalogGate()
              .evaluate(parsed, context: publicationContext)
              .isAvailable,
          isFalse);
    });

    for (final status in [
      'openLicense',
      'permissionPending',
      'unauthorized',
      'restricted',
      'unknown',
    ]) {
      test('rejects $status rights without explicit use authorization', () {
        final json = publishableFixture(fixtureText);
        (json['sources'] as List<dynamic>).first['rightsStatus'] = status;
        final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));

        expect(
          const PublishableCatalogGate()
              .evaluate(parsed, context: publicationContext)
              .isAvailable,
          isFalse,
        );
      });
    }

    test('rejects a supported documentary claim', () {
      final json = publishableFixture(fixtureText);
      (json['claims'] as List<dynamic>).first['verificationStatus'] =
          'supported';
      final parsed = DreamsCatalogLoader().loadString(jsonEncode(json));

      expect(
          const PublishableCatalogGate()
              .evaluate(parsed, context: publicationContext)
              .isAvailable,
          isFalse);
    });

    test('returns deeply immutable catalog collections', () {
      final approved = DreamsCatalogLoader()
          .loadString(jsonEncode(publishableFixture(fixtureText)));
      final safe = const PublishableCatalogGate()
          .evaluate(approved, context: publicationContext)
          .catalog!;

      expect(
          () => safe.sources.add(safe.sources.first), throwsUnsupportedError);
      expect(() => safe.entries.first.variants.clear(), throwsUnsupportedError);
      expect(() => safe.interpretations.first.sourceReferences.clear(),
          throwsUnsupportedError);
      expect(() => safe.conflictGroups.first.claimIds.clear(),
          throwsUnsupportedError);
      expect(() => safe.rightsEvidence.first.scopeReferences.clear(),
          throwsUnsupportedError);
      expect(() => safe.rightsEvidence.first.historicalFactReferences.clear(),
          throwsUnsupportedError);
      expect(() => safe.rightsEvidence.first.licenseConditions.clear(),
          throwsUnsupportedError);
      expect(() => safe.rightsEvidence.first.legalLimitations.clear(),
          throwsUnsupportedError);
    });

    test('safe search and analyzer preserve sources and conflicts', () {
      final approved = DreamsCatalogLoader()
          .loadString(jsonEncode(publishableFixture(fixtureText)));
      final safe = const PublishableCatalogGate()
          .evaluate(approved, context: publicationContext)
          .catalog!;

      final search = safe.search('10').single;
      expect(search.conflicts.single.id, 'conflict_fixture_a');
      final analysis = safe.analyze('Vi una señal alfa.');
      expect(
        analysis.matches.single.sources.map((item) => item.id),
        containsAll(['source_fixture_authorized', 'source_fixture_pending']),
      );
      expect(analysis.matches.single.claims.map((item) => item.number),
          ['10', '20']);
      expect(analysis.matches.single.conflicts.single.id, 'conflict_fixture_a');
    });
  });

  group('deterministic search', () {
    test('searches by two-digit number and retains conflicts', () {
      final result = DreamsCatalogSearch(catalog).search('10').single;
      expect(result.entry.id, 'simbolo_prueba_a');
      expect(result.matchType, CatalogMatchType.number);
      expect(result.conflicts.single.id, 'conflict_fixture_a');
    });

    test('normalizes accents and letter case', () {
      final result = DreamsCatalogSearch(catalog).search('SIMBOLO PRUEBA A');
      expect(result.first.entry.id, 'simbolo_prueba_a');
      expect(result.first.matchType, CatalogMatchType.canonicalExact);
    });

    test('prioritizes exact canonical matches over partial matches', () {
      final results = DreamsCatalogSearch(catalog).search('símbolo prueba b');
      expect(results.first.entry.id, 'simbolo_prueba_b');
      expect(results.first.matchType, CatalogMatchType.canonicalExact);
    });

    test('searches variants and reports ambiguous terms', () {
      final results = DreamsCatalogSearch(catalog).search('eco prueba');
      expect(results.map((item) => item.entry.id),
          containsAll(['simbolo_prueba_a', 'simbolo_prueba_b']));
      expect(results.where((item) => item.ambiguous), hasLength(1));
      expect(results.first.entry.id, 'simbolo_prueba_b');
    });

    test('returns no result for undocumented terms', () {
      expect(DreamsCatalogSearch(catalog).search('sin ficha'), isEmpty);
    });
  });

  group('local dream description analyzer', () {
    test('recognizes full phrases and returns original fragments', () {
      final result = DreamDescriptionAnalyzer(catalog)
          .analyze('Vi una señal de prueba larga anoche.');
      expect(result.matches, hasLength(1));
      expect(result.matches.single.entry.id, 'simbolo_prueba_c');
      expect(result.matches.single.fragment, 'señal de prueba larga');
      expect(result.matches.single.claims.single.number, '40');
      expect(
          result.matches.single.sources.single.id, 'source_fixture_authorized');
    });

    test('detects negation and does not activate associations', () {
      final result = DreamDescriptionAnalyzer(catalog)
          .analyze('No había ningún símbolo prueba A.');
      final match = result.matches.single;
      expect(match.negated, isTrue);
      expect(match.claims, isEmpty);
      expect(result.hasActiveAssociations, isFalse);
    });

    test('does not promote related terms to exact associations', () {
      final result =
          DreamDescriptionAnalyzer(catalog).analyze('Vi un objeto cercano.');
      final match = result.matches.single;
      expect(match.relationType, RelationType.related);
      expect(match.associationEligible, isFalse);
      expect(match.claims, isEmpty);
    });

    test('reports ambiguous variants without hiding either entry', () {
      final result =
          DreamDescriptionAnalyzer(catalog).analyze('Apareció un eco prueba.');
      expect(result.matches, hasLength(2));
      expect(result.matches.every((item) => item.ambiguous), isTrue);
    });

    test('avoids duplicate canonical and nested matches for one entry', () {
      final result = DreamDescriptionAnalyzer(catalog)
          .analyze('El símbolo prueba compuesto estaba presente.');
      expect(
        result.matches.where((item) => item.entry.id == 'simbolo_prueba_c'),
        hasLength(1),
      );
    });

    test('returns documentary absence instead of inventing a match', () {
      final result =
          DreamDescriptionAnalyzer(catalog).analyze('Apareció algo sin ficha.');
      expect(result.hasDocumentaryMatches, isFalse);
      expect(result.matches, isEmpty);
    });
  });
}
