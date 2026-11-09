import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/data/dreams_catalog_loader.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/domain/catalog_validation.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/domain/dreams_catalog.dart';

const reviewCatalogPath =
    '../docs/dreams_numbers/review_catalog/dominican_cultural_review_catalog.json';

void main() {
  late DreamsCatalog catalog;

  setUpAll(() async {
    catalog = await DreamsCatalogLoader().loadFile(reviewCatalogPath);
  });

  group('Phase 5.6 cultural review catalog', () {
    test('loads as schema 1.2 review material with four articles', () {
      expect(catalog.metadata.schemaVersion, '1.2.0');
      expect(catalog.metadata.editorialStatus, PublicationStatus.review);
      expect(catalog.articles, hasLength(4));
      expect(catalog.articles.map((article) => article.id).toSet(),
          {'a1', 'a2', 'a3', 'a5'});
    });

    test('excludes blocked A4 and all numerical catalog material', () {
      expect(catalog.articles.any((article) => article.id == 'a4'), isFalse);
      expect(catalog.entries, isEmpty);
      expect(catalog.claims, isEmpty);
      expect(catalog.interpretations, isEmpty);
      expect(catalog.conflictGroups, isEmpty);
    });

    test('keeps every article and rights record pending review', () {
      expect(
        catalog.articles,
        everyElement(
          isA<CulturalArticle>()
              .having((article) => article.publicationStatus, 'publication',
                  PublicationStatus.review)
              .having((article) => article.rightsStatus, 'rights',
                  RightsStatus.permissionPending),
        ),
      );
      expect(catalog.rightsEvidence, hasLength(4));
      expect(
        catalog.rightsEvidence,
        everyElement(
          isA<RightsEvidence>()
              .having((evidence) => evidence.reviewStatus, 'review',
                  RightsReviewStatus.pending)
              .having((evidence) => evidence.legalBasisType, 'basis',
                  LegalBasisType.originalWork),
        ),
      );
    });

    test('contains no commercial table, pilot card, or predictive content', () {
      final serialized = File(reviewCatalogPath).readAsStringSync();
      expect(serialized, isNot(contains('00–99')));
      expect(serialized, isNot(contains('00-99')));
      expect(serialized, isNot(contains('ficha piloto')));
      expect(serialized, isNot(contains('publicDomain')));
      expect(
        catalog.articles.every((article) =>
            !RegExp(r'"number"\s*:').hasMatch(article.text) &&
            !article.text.toLowerCase().contains('predicción garantizada')),
        isTrue,
      );
    });

    test('is rejected by the publication gate', () {
      final context = PublicationContext(
        referenceDate: DateTime.utc(2026, 11, 9),
      );
      final issues =
          const CatalogValidator().validateForPublication(catalog, context);

      expect(issues, isNotEmpty);
      expect(
        issues.map((issue) => issue.message),
        contains('Catalog is not approved for publication.'),
      );
      expect(
        () => const CatalogValidator().requirePublishable(catalog, context),
        throwsA(isA<CatalogValidationException>()),
      );
    });

    test('is not referenced by application source or production assets', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(contains('review_catalog')));

      final references = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => file.readAsStringSync().contains('review_catalog'));
      expect(references, isEmpty);
    });
  });
}
