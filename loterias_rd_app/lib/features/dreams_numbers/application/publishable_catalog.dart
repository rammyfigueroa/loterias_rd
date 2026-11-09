import '../domain/catalog_validation.dart';
import '../domain/dreams_catalog.dart';
import 'dream_description_analyzer.dart';
import 'dreams_catalog_search.dart';

class PublishableDreamsCatalog {
  final DreamsCatalog _catalog;

  PublishableDreamsCatalog._(DreamsCatalog catalog)
      : _catalog = _freezeCatalog(catalog);

  CatalogMetadata get metadata => _catalog.metadata;
  List<Source> get sources => _catalog.sources;
  List<CatalogEntry> get entries => _catalog.entries;
  List<DocumentaryClaim> get claims => _catalog.claims;
  List<EditorialInterpretation> get interpretations => _catalog.interpretations;
  List<ConflictGroup> get conflictGroups => _catalog.conflictGroups;
  List<RightsEvidence> get rightsEvidence => _catalog.rightsEvidence;
  List<CulturalArticle> get articles => _catalog.articles;

  Source sourceById(String id) => _catalog.sourceById(id);
  CatalogEntry entryById(String id) => _catalog.entryById(id);
  List<DocumentaryClaim> claimsFor(String entryId) =>
      List.unmodifiable(_catalog.claimsFor(entryId));
  List<ConflictGroup> conflictsForClaims(Iterable<String> claimIds) =>
      List.unmodifiable(_catalog.conflictsForClaims(claimIds));

  List<CatalogSearchResult> search(String query) =>
      List.unmodifiable(DreamsCatalogSearch(_catalog).search(query));

  DreamAnalysisResult analyze(String description) =>
      DreamDescriptionAnalyzer(_catalog).analyze(description);

  static DreamsCatalog _freezeCatalog(DreamsCatalog catalog) {
    final sources = catalog.sources
        .map((source) => Source(
              id: source.id,
              title: source.title,
              author: source.author,
              publisher: source.publisher,
              url: source.url,
              publicationDate: source.publicationDate,
              accessDate: source.accessDate,
              sourceType: source.sourceType,
              jurisdiction: source.jurisdiction,
              rightsStatus: source.rightsStatus,
              verificationStatus: source.verificationStatus,
            ))
        .toList(growable: false);
    final entries = catalog.entries
        .map((entry) => CatalogEntry(
              id: entry.id,
              canonicalTerm: entry.canonicalTerm,
              category: entry.category,
              description: entry.description,
              variants:
                  List.unmodifiable(entry.variants.map((variant) => TermVariant(
                        term: variant.term,
                        relationType: variant.relationType,
                        context: variant.context,
                        locale: variant.locale,
                      ))),
            ))
        .toList(growable: false);
    final claims = catalog.claims
        .map((claim) => DocumentaryClaim(
              id: claim.id,
              catalogEntryId: claim.catalogEntryId,
              number: claim.number,
              sourceId: claim.sourceId,
              sourceLocation: claim.sourceLocation,
              verificationStatus: claim.verificationStatus,
              notes: claim.notes,
              rightsEvidenceIds: List.unmodifiable(claim.rightsEvidenceIds),
            ))
        .toList(growable: false);
    final interpretations = catalog.interpretations
        .map((interpretation) => EditorialInterpretation(
              id: interpretation.id,
              catalogEntryId: interpretation.catalogEntryId,
              text: interpretation.text,
              sourceReferences:
                  List.unmodifiable(interpretation.sourceReferences),
              verificationStatus: interpretation.verificationStatus,
              publicationStatus: interpretation.publicationStatus,
              rightsEvidenceIds:
                  List.unmodifiable(interpretation.rightsEvidenceIds),
            ))
        .toList(growable: false);
    final evidence = catalog.rightsEvidence
        .map((item) => RightsEvidence(
              id: item.id,
              sourceId: item.sourceId,
              rightsHolder: item.rightsHolder,
              authorizationType: item.authorizationType,
              evidenceReference: item.evidenceReference,
              evidenceDate: item.evidenceDate,
              validFrom: item.validFrom,
              validUntil: item.validUntil,
              indefiniteTermJustification: item.indefiniteTermJustification,
              territory: item.territory,
              territories: List.unmodifiable(item.territories),
              commercialUseAllowed: item.commercialUseAllowed,
              redistributionAllowed: item.redistributionAllowed,
              derivativeWorksAllowed: item.derivativeWorksAllowed,
              attributionRequired: item.attributionRequired,
              restrictions: List.unmodifiable(item.restrictions),
              reviewStatus: item.reviewStatus,
              reviewedAt: item.reviewedAt,
              scopeType: item.scopeType,
              scopeReferences: List.unmodifiable(item.scopeReferences),
              legalBasisType: item.legalBasisType,
              authorshipReference: item.authorshipReference,
              originalityDeclaration: item.originalityDeclaration,
              editorialReviewReference: item.editorialReviewReference,
              historicalFactReferences:
                  List.unmodifiable(item.historicalFactReferences),
              unauthorizedReproductionConfirmedAbsent:
                  item.unauthorizedReproductionConfirmedAbsent,
              licenseIdentifier: item.licenseIdentifier,
              licenseVersion: item.licenseVersion,
              licenseUrl: item.licenseUrl,
              licenseConditions: List.unmodifiable(item.licenseConditions),
              attributionReference: item.attributionReference,
              legalJurisdiction: item.legalJurisdiction,
              legalException: item.legalException,
              legalReviewReference: item.legalReviewReference,
              legalReviewerRole: item.legalReviewerRole,
              legalConclusionDate: item.legalConclusionDate,
              legalLimitations: List.unmodifiable(item.legalLimitations),
            ))
        .toList(growable: false);
    final articles = catalog.articles
        .map((item) => CulturalArticle(
              id: item.id,
              title: item.title,
              category: item.category,
              text: item.text,
              sourceReferences: List.unmodifiable(item.sourceReferences),
              rightsEvidenceIds: List.unmodifiable(item.rightsEvidenceIds),
              verificationStatus: item.verificationStatus,
              rightsStatus: item.rightsStatus,
              publicationStatus: item.publicationStatus,
              reviewedAt: item.reviewedAt,
            ))
        .toList(growable: false);
    final conflicts = catalog.conflictGroups
        .map((conflict) => ConflictGroup(
              id: conflict.id,
              claimIds: List.unmodifiable(conflict.claimIds),
              conflictType: conflict.conflictType,
              explanation: conflict.explanation,
            ))
        .toList(growable: false);

    return DreamsCatalog(
      metadata: CatalogMetadata(
        schemaVersion: catalog.metadata.schemaVersion,
        catalogVersion: catalog.metadata.catalogVersion,
        locale: catalog.metadata.locale,
        generatedAt: catalog.metadata.generatedAt,
        editorialStatus: catalog.metadata.editorialStatus,
      ),
      sources: List.unmodifiable(sources),
      entries: List.unmodifiable(entries),
      claims: List.unmodifiable(claims),
      interpretations: List.unmodifiable(interpretations),
      conflictGroups: List.unmodifiable(conflicts),
      rightsEvidence: List.unmodifiable(evidence),
      articles: List.unmodifiable(articles),
    );
  }
}

class PublishableCatalogResult {
  final PublishableDreamsCatalog? catalog;
  final List<CatalogValidationIssue> issues;

  const PublishableCatalogResult._({this.catalog, this.issues = const []});

  const PublishableCatalogResult.unavailable() : this._(issues: const []);

  bool get isAvailable => catalog != null;
}

class PublishableCatalogGate {
  final CatalogValidator validator;

  const PublishableCatalogGate({this.validator = const CatalogValidator()});

  PublishableCatalogResult evaluate(
    DreamsCatalog catalog, {
    required PublicationContext context,
  }) {
    final issues = validator.validateForPublication(catalog, context);
    if (issues.isNotEmpty) {
      return PublishableCatalogResult._(issues: List.unmodifiable(issues));
    }
    return PublishableCatalogResult._(
      catalog: PublishableDreamsCatalog._(catalog),
    );
  }
}
